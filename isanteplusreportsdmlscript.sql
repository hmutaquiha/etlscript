use isanteplus;
DELIMITER $$
	DROP PROCEDURE IF EXISTS isanteplusreports_dml$$
	CREATE PROCEDURE isanteplusreports_dml()
		BEGIN
		 /*Started DML queries*/
			/* insert data to patient table */
			SET SQL_SAFE_UPDATES = 0;
			SET FOREIGN_KEY_CHECKS=0;
					insert into patient
					(
					 patient_id,
					 given_name,
					 family_name,
					 gender,
					 birthdate, 
					 creator, 
					 date_created,
					 last_inserted_date
					)
					select pn.person_id,
						   pn.given_name,
						   pn.family_name,
						   pe.gender,
						   pe.birthdate,
						   pn.creator,
						   pn.date_created,
						   now() as last_inserted_date 
					from openmrs.person_name pn, openmrs.person pe, openmrs.patient pa 
					where pe.person_id=pn.person_id AND pe.person_id=pa.patient_id
					on duplicate key update 
						given_name=pn.given_name,
						family_name=pn.family_name,
						gender=pe.gender,
						birthdate=pe.birthdate,
						creator=pn.creator,
						date_created=pn.date_created;

			/* update patient with identifier */
			
			update patient p,openmrs.patient_identifier pi set p.st_id=pi.identifier 
			where p.patient_id=pi.patient_id and identifier_type=1;

			update patient p,openmrs.patient_identifier pi set p.national_id=pi.identifier 
			where p.patient_id=pi.patient_id and identifier_type=2;

			/* update location_id for patients*/
			
			
				update patient p,(select distinct patient_id,location_id from openmrs.patient_identifier) pi set p.location_id=pi.location_id 
				where p.patient_id=pi.patient_id;
				
			/* update patient with person attribute */
			
			update patient pat,(
			select  
			(select p1.value from openmrs.person_attribute p1
			where p1.person_id=p.person_id and
			pa.uuid='8d8718c2-c2cc-11de-8d13-0010c6dffd0f' LIMIT 1) as birthPlace,
			(select p1.value from openmrs.person_attribute p1 
			where p1.person_id=p.person_id and
			pa.uuid='14d4f066-15f5-102d-96e4-000c29c2a5d7' LIMIT 1) as phone,
			(select p1.value from openmrs.person_attribute p1 
			where p1.person_id=p.person_id and 
			pa.uuid='8d871f2a-c2cc-11de-8d13-0010c6dffd0f' LIMIT 1) as civilStatus,
			(select p1.value from openmrs.person_attribute p1 
			where p1.person_id=p.person_id and 
			pa.uuid='e55fd643-a731-4ff4-83c1-c07827b19722' LIMIT 1) as occupation,
			(select p1.value from openmrs.person_attribute p1 
			where p1.person_id=p.person_id and 
			pa.uuid='8d871d18-c2cc-11de-8d13-0010c6dffd0f' LIMIT 1) as motherName,
			p.* from openmrs.person_attribute p,openmrs.person_attribute_type pa
			where  pa.person_attribute_type_id=p.person_attribute_type_id
			) p2 set pat.maritalStatus=p2.civilStatus,
					 pat.occupation=p2.occupation,
					 pat.telephone=p2.phone,
					 pat.place_of_birth=p2.birthPlace,
					 pat.mother_name=p2.motherName
					 WHERE pat.patient_id=p2.person_id;

			/* update patient with vih status */
			
			UPDATE patient p, openmrs.encounter en, openmrs.encounter_type ent
			SET p.vih_status=1
			WHERE p.patient_id=en.patient_id AND en.encounter_type=ent.encounter_type_id
			AND (ent.uuid='17536ba6-dd7c-4f58-8014-08c7cb798ac7'
			 OR ent.uuid='204ad066-c5c2-4229-9a62-644bc5617ca2'
			 OR ent.uuid='349ae0b4-65c1-4122-aa06-480f186c8350'
			 OR ent.uuid='33491314-c352-42d0-bd5d-a9d0bffc9bf1');

			/* update patient with death information */


			/* insert data to patient_visit table */
			
			REPLACE INTO patient_visit
			(visit_date,visit_id,encounter_id,location_id,
			 patient_id,start_date,stop_date,creator,
			 encounter_type,form_id,next_visit_date,
			last_insert_date)
			select v.date_started as visit_date,
				   v.visit_id,e.encounter_id,v.location_id,
				   v.patient_id,v.date_started,v.date_stopped,
				   v.creator,e.encounter_type,e.form_id,o.value_datetime as next_visit_date,
				   now() as last_insert_date
			from openmrs.visit v,openmrs.encounter e,openmrs.obs o
			where v.visit_id=e.visit_id and v.patient_id=e.patient_id
				  and o.person_id=e.patient_id and o.encounter_id=e.encounter_id
				and o.concept_id='5096';
		/*---------------------------------------------------*/	
/*Queries for filling the patient_tb_diagnosis table*/
/*Insert when Tuberculose [A15.0] remplir la section Tuberculose ci-dessous
 AND MDR TB remplir la section Tuberculose ci-dessous [Z16.24] areas are checked*/
insert into patient_tb_diagnosis
					(
					 patient_id,
					 encounter_id,
					 location_id
					)
					select distinct ob.person_id,
						   ob.encounter_id,ob.location_id
					from openmrs.obs ob, openmrs.obs ob1
					where ob.person_id=ob1.person_id
					AND ob.encounter_id=ob1.encounter_id
					AND ob.obs_group_id=ob1.obs_id
                    AND ob1.concept_id=159947	
					AND (ob.concept_id=1284 AND ob.value_coded=112141
						OR
						ob.concept_id=1284 AND ob.value_coded=159345)
						on duplicate key update
						patient_id=ob.person_id,
						encounter_id=ob.encounter_id;
/*Insert when Nouveau diagnostic Or suivi in the tuberculose menu are checked*/						
insert into patient_tb_diagnosis
					(
						patient_id,
						encounter_id,
						location_id
					)
			select distinct ob.person_id,ob.encounter_id,ob.location_id
			FROM openmrs.obs ob
			where ob.concept_id=1659
			AND (ob.value_coded=160567 OR ob.value_coded=1662)
			AND ob.encounter_id not in 
			(select encounter_id from patient_tb_diagnosis)
			on duplicate key update
			patient_id=ob.person_id,
			encounter_id=ob.encounter_id;
/*Insert when the area Toux >= 2 semaines is checked*/			
insert into patient_tb_diagnosis
					(
						patient_id,
						encounter_id,
						location_id
					)
			select distinct ob.person_id,ob.encounter_id,ob.location_id
			FROM openmrs.obs ob
			where ob.concept_id=159614
			AND ob.value_coded=159799
			AND ob.encounter_id not in 
			(select encounter_id from patient_tb_diagnosis)
			on duplicate key update
			patient_id=ob.person_id,
			encounter_id=ob.encounter_id;
/*Insert when one of the status tb is checked on the resultat du traitement(tb) menu*/			
insert into patient_tb_diagnosis
					(
						patient_id,
						encounter_id,
						location_id
					)
			select distinct ob.person_id,ob.encounter_id,ob.location_id
			FROM openmrs.obs ob
			where ob.concept_id=159786
			AND (ob.value_coded=159791 OR ob.value_coded=160035
				OR ob.value_coded=159874 OR ob.value_coded=160031
				OR ob.value_coded=160034)
			AND ob.encounter_id not in 
			(select encounter_id from patient_tb_diagnosis)
			on duplicate key update
			patient_id=ob.person_id,
			encounter_id=ob.encounter_id;
/*update for visit_id AND visit_date*/ 
update patient_tb_diagnosis pat, openmrs.visit vi, openmrs.encounter en
   set pat.visit_id=vi.visit_id, pat.visit_date=vi.date_started
	where pat.encounter_id=en.encounter_id
	AND en.visit_id=vi.visit_id;
/*update provider ???*/
update patient_tb_diagnosis pat, openmrs.encounter_provider enp
	set pat.provider_id=enp.provider_id
	WHERE pat.encounter_id=enp.encounter_id;
/*Update tb_diag and mdr_tb_diag*/
update patient_tb_diagnosis pat, openmrs.obs ob,openmrs.obs ob1
	set pat.tb_diag=1
	where ob.obs_group_id=ob1.obs_id
    AND ob1.concept_id=159947	
	AND (ob.concept_id=1284 AND ob.value_coded=112141)
	AND pat.encounter_id=ob.encounter_id;
					
	update patient_tb_diagnosis pat, openmrs.obs ob,openmrs.obs ob1
	set pat.mdr_tb_diag=1
	where ob.obs_group_id=ob1.obs_id
    AND ob1.concept_id=159947	
	AND (ob.concept_id=1284 AND ob.value_coded=159345)
	AND pat.encounter_id=ob.encounter_id;
/*update tb_new_diag AND tb_follow_up_diag*/
	update patient_tb_diagnosis pat, openmrs.obs ob
	SET pat.tb_new_diag=1
	WHERE pat.encounter_id=ob.encounter_id
	AND (ob.concept_id=1659 AND ob.value_coded=160567);
	
	update patient_tb_diagnosis pat, openmrs.obs ob
	SET pat.tb_follow_up_diag=1
	WHERE pat.encounter_id=ob.encounter_id
	AND (ob.concept_id=1659 AND ob.value_coded=1662);
/*update cough_for_2wks_or_more*/
	update patient_tb_diagnosis pat, openmrs.obs ob
	SET pat.cough_for_2wks_or_more=1
	WHERE pat.encounter_id=ob.encounter_id
	AND (ob.concept_id=159614 AND ob.value_coded=159799);
/*update tb_treatment_start_date*/
	update patient_tb_diagnosis pat, openmrs.obs ob
	SET pat.tb_treatment_start_date=ob.value_datetime
	WHERE pat.encounter_id=ob.encounter_id
	AND ob.concept_id=1113;
/*update for status_tb_treatment*/
/*
	statuts_tb_treatment = Gueri(1),traitement termine(2),
		Abandon(3),tranfere(4),decede(5)
<obs conceptId="CIEL:159786" 
answerConceptIds="CIEL:159791,CIEL:160035,CIEL:159874,CIEL:160031,CIEL:160034" 
answerLabels="Guéri,Traitement Terminé,Abandon,Transféré,Décédé" style="radio"/>
*/
update patient_tb_diagnosis pat, openmrs.obs ob
	SET pat.status_tb_treatment=
	CASE WHEN ob.value_coded=159791 then 1
	when ob.value_coded=160035 then 2
	when ob.value_coded=159874 then 3
	when ob.value_coded=160031 then 4
	when ob.value_coded=160034 then 5
	END
	WHERE pat.encounter_id=ob.encounter_id
	AND ob.concept_id=159786;
/*update tb_treatment_stop_date*/
   update patient_tb_diagnosis pat, openmrs.obs ob
	SET pat.tb_treatment_stop_date=ob.value_datetime
	WHERE pat.encounter_id=ob.encounter_id
	AND ob.concept_id=159431;
/*Insert for patient_id,encounter_id, drug_id areas*/
  REPLACE into patient_dispensing
					(
					 patient_id,
					 encounter_id,
					 location_id,
					 drug_id,
					 dispensation_date
					)
					select distinct ob.person_id,
					ob.encounter_id,ob.location_id,ob.value_coded,ob2.obs_datetime
					from openmrs.obs ob, openmrs.obs ob1,openmrs.obs ob2
					where ob.person_id=ob1.person_id
					AND ob.encounter_id=ob1.encounter_id
					AND ob.obs_group_id=ob1.obs_id
					AND ob1.obs_id = ob2.obs_group_id
                    AND ob1.concept_id=163711	
					AND ob.concept_id=1282
					AND ob2.concept_id=1276;

	/*update provider for patient_dispensing???*/
	update patient_dispensing padisp, openmrs.encounter_provider enp
	set padisp.provider_id=enp.provider_id
	WHERE padisp.encounter_id=enp.encounter_id;
	/*Update dose_day, pill_amount for patient_dispensing*/
	update isanteplus.patient_dispensing patdisp, openmrs.obs ob, openmrs.obs ob1
	SET patdisp.dose_day=ob.value_numeric
	WHERE patdisp.encounter_id=ob.encounter_id
	AND ob.encounter_id=ob1.encounter_id
	AND ob.obs_group_id=ob1.obs_id
    AND ob1.concept_id=163711
	AND ob.concept_id=159368;
	/*Update pill_amount for patient_dispensing*/
	update isanteplus.patient_dispensing patdisp, openmrs.obs ob, openmrs.obs ob1
	SET patdisp.pills_amount=ob.value_numeric
	WHERE patdisp.encounter_id=ob.encounter_id
	AND ob.encounter_id=ob1.encounter_id
	AND ob.obs_group_id=ob1.obs_id
    AND ob1.concept_id=163711
	AND ob.concept_id=1443;
	/*update next_dispensation_date for table patient_dispensing*/	
	update patient_dispensing patdisp, openmrs.obs ob 
	set patdisp.next_dispensation_date=ob.value_datetime
	WHERE patdisp.encounter_id=ob.encounter_id
	AND ob.concept_id=162549;
   /*update visit_id, visit_date for table patient_dispensing*/
	update patient_dispensing patdisp, openmrs.visit vi, openmrs.encounter en
   set patdisp.visit_id=vi.visit_id, patdisp.visit_date=vi.date_started
	where patdisp.encounter_id=en.encounter_id
	AND en.visit_id=vi.visit_id;		
		/*Insertion for patient_id, visit_id,encounter_id,visit_date for table patient_imagerie */
insert into patient_imagerie (patient_id,location_id,visit_id,encounter_id,visit_date)
	select distinct ob.person_id,ob.location_id,vi.visit_id, ob.encounter_id,vi.date_started
	from openmrs.obs ob, openmrs.encounter en, 
	openmrs.encounter_type enctype, openmrs.visit vi
	WHERE ob.encounter_id=en.encounter_id
	AND en.encounter_type=enctype.encounter_type_id
	AND en.visit_id=vi.visit_id
	AND(ob.concept_id=12 or ob.concept_id=309 or ob.concept_id=307)
	AND enctype.uuid='a4cab59f-f0ce-46c3-bd76-416db36ec719'
	on duplicate key update
	encounter_id=ob.encounter_id;
/*update radiographie_pul of table patient_imagerie*/
update isanteplus.patient_imagerie patim, openmrs.obs ob
set patim.radiographie_pul=ob.value_coded
WHERE patim.encounter_id=ob.encounter_id
AND ob.concept_id=12;
/*update radiographie_autre of table patient_imagerie*/
update isanteplus.patient_imagerie patim, openmrs.obs ob
set patim.radiographie_autre=ob.value_coded
WHERE patim.encounter_id=ob.encounter_id
AND ob.concept_id=309;
/*update crachat_barr of table patient_imagerie*/
update isanteplus.patient_imagerie patim, openmrs.obs ob
set patim.crachat_barr=ob.value_coded
WHERE patim.encounter_id=ob.encounter_id
AND ob.concept_id=307;

/*Part of patient Status*/

 TRUNCATE TABLE patient_on_arv;
	INSERT INTO patient_on_arv(patient_id,visit_id,visit_date)
	SELECT DISTINCT v.patient_id,v.visit_id,MAX(v.date_started)
	FROM openmrs.visit v, openmrs.encounter enc, openmrs.obs ob,
	openmrs.obs ob1, openmrs.obs ob2
	WHERE v.visit_id=enc.visit_id
	AND enc.encounter_id=ob.encounter_id
	AND ob.person_id=ob1.person_id
	AND ob.encounter_id=ob1.encounter_id
	AND ob.obs_group_id=ob1.obs_id
	AND ob1.obs_id = ob2.obs_group_id
	AND ob1.concept_id=163711	
	AND ob.concept_id=1282
	AND ob2.concept_id=1276
	AND ob.value_coded IN(SELECT darv.drug_id 
	FROM isanteplus.arv_drugs darv)
	GROUP BY v.patient_id;
	
	
	TRUNCATE TABLE discontinuation_reason;
INSERT INTO 
 discontinuation_reason(patient_id,visit_id,visit_date,reason,reason_name)
SELECT DISTINCT v.patient_id,v.visit_id,
			MAX(v.date_started),ob.value_coded,
		CASE WHEN(ob.value_coded=5240) THEN 'Perdu de vue'
		    WHEN (ob.value_coded=159492) THEN 'Transfert'
			WHEN (ob.value_coded=159) THEN 'Décès'
			WHEN (ob.value_coded=1667) THEN 'Discontinuations'
			WHEN (ob.value_coded=1067) THEN 'Inconnue'
		END
	FROM openmrs.visit v, openmrs.encounter enc,
	openmrs.encounter_type etype,openmrs.obs ob
	WHERE v.visit_id=enc.visit_id
	AND enc.encounter_type=etype.encounter_type_id
	AND enc.encounter_id=ob.encounter_id
	AND etype.uuid='9d0113c6-f23a-4461-8428-7e9a7344f2ba'
	AND ob.concept_id=161555
	Group BY v.patient_id;
	
	
	/*Insertion for patient_status Décédés=1,Arrêtés=2,Transférés=3 on ARV*/
REPLACE INTO patient_status_ARV(patient_id,id_status,start_date)
	SELECT DISTINCT v.patient_id,
	CASE WHEN (ob.value_coded=159) THEN 1
	WHEN (ob.value_coded=5240) THEN 2
	WHEN (ob.value_coded=159492) THEN 3
	END,MAX(v.start_date)
	FROM isanteplus.patient_visit v,openmrs.encounter enc,
	openmrs.encounter_type entype,openmrs.obs ob
	WHERE v.visit_id=enc.visit_id
	AND enc.encounter_type=entype.encounter_type_id
	AND enc.encounter_id=ob.encounter_id
	AND entype.uuid='9d0113c6-f23a-4461-8428-7e9a7344f2ba'
	AND ob.concept_id=161555
	AND enc.patient_id IN (SELECT parv.patient_id 
	FROM isanteplus.patient_on_arv parv)
	GROUP BY v.patient_id;
	
	
/*====================================================*/
/*Insertion for patient_status Décédés en Pré-ARV=4,
Transférés en Pré-ARV=5*/
REPLACE INTO patient_status_ARV(patient_id,id_status,start_date)
	SELECT DISTINCT v.patient_id,
	CASE WHEN (ob.value_coded=159) THEN 4
	WHEN (ob.value_coded=159492) THEN 5
	END,MAX(v.start_date)
	FROM isanteplus.patient ispat,isanteplus.patient_visit v,
	openmrs.encounter_type entype,openmrs.encounter enc,
	openmrs.obs ob
	WHERE ispat.patient_id=v.patient_id
	AND v.visit_id=enc.visit_id
	AND entype.encounter_type_id=enc.encounter_type
	AND enc.encounter_id=ob.encounter_id
	AND entype.uuid='9d0113c6-f23a-4461-8428-7e9a7344f2ba'
	AND ob.concept_id=161555
	AND ispat.vih_status=1
	AND enc.patient_id NOT IN (SELECT parv.patient_id 
	FROM isanteplus.patient_on_arv parv)
	AND ob.value_coded IN(159,159492)
	GROUP BY v.patient_id;
	/*Insertion for patient_status réguliers=6*/
/*A VERIFIER*/
REPLACE INTO patient_status_ARV(patient_id,id_status,start_date)
	SELECT DISTINCT v.patient_id,6,MAX(v.start_date)
	FROM isanteplus.patient ipat,isanteplus.patient_visit v,
	openmrs.encounter enc,
	openmrs.encounter_type entype
	WHERE ipat.patient_id=v.patient_id
	AND v.visit_id=enc.visit_id
	AND enc.encounter_type=entype.encounter_type_id
	AND enc.patient_id
	NOT IN(SELECT dreason.patient_id FROM discontinuation_reason dreason
	WHERE dreason.reason IN(159,5240,159492))
	AND enc.patient_id IN (SELECT parv.patient_id 
	FROM isanteplus.patient_on_arv parv)
	AND entype.uuid NOT IN ('f037e97b-471e-4898-a07c-b8e169e0ddc4',
	                        'a0d57dca-3028-4153-88b7-c67a30fde595',
							'51df75f7-a3de-4f82-a9df-c0bedaf5a2dd'
							)
	AND(DATE(now()) < v.next_visit_date)
	GROUP BY v.patient_id;
/*Insertion for patient_status Rendez-vous ratés=8*/
  REPLACE INTO patient_status_ARV(patient_id,id_status,start_date)
	SELECT DISTINCT v.patient_id,8,MAX(v.start_date)
	FROM isanteplus.patient ipat,isanteplus.patient_visit v,
	openmrs.encounter enc,
	openmrs.encounter_type entype
	WHERE ipat.patient_id=v.patient_id
	AND v.visit_id=enc.visit_id
	AND enc.encounter_type=entype.encounter_type_id
	AND enc.patient_id	
	NOT IN(SELECT dreason.patient_id FROM discontinuation_reason dreason
	WHERE dreason.reason IN(159,5240,159492))
	AND enc.patient_id IN (SELECT parv.patient_id 
	FROM isanteplus.patient_on_arv parv)
	AND entype.uuid NOT IN ('f037e97b-471e-4898-a07c-b8e169e0ddc4',
	                        'a0d57dca-3028-4153-88b7-c67a30fde595',
							'51df75f7-a3de-4f82-a9df-c0bedaf5a2dd'
							)
	AND((DATE(now()) > v.next_visit_date))
	GROUP BY v.patient_id
	UNION ALL
	SELECT DISTINCT pdis.patient_id,8,MAX(DATE(pdis.visit_date))
	FROM isanteplus.patient ipat,isanteplus.patient_dispensing pdis,
	openmrs.encounter enc,
	openmrs.encounter_type entype
	WHERE ipat.patient_id=pdis.patient_id
	AND pdis.visit_id=enc.visit_id
	AND enc.encounter_type=entype.encounter_type_id
	AND enc.patient_id	
	NOT IN(SELECT dreason.patient_id FROM discontinuation_reason dreason
	WHERE dreason.reason IN(159,5240,159492))
	AND enc.patient_id IN (SELECT parv.patient_id 
	FROM isanteplus.patient_on_arv parv)
	AND entype.uuid NOT IN ('f037e97b-471e-4898-a07c-b8e169e0ddc4',
	                        'a0d57dca-3028-4153-88b7-c67a30fde595',
							'51df75f7-a3de-4f82-a9df-c0bedaf5a2dd'
							) 
	AND (DATEDIFF(DATE(now()),pdis.next_dispensation_date)<=90)
	GROUP BY pdis.patient_id;		
/*Insertion for patient_status Perdus de vue=9*/
REPLACE INTO patient_status_ARV(patient_id,id_status,start_date)
	SELECT DISTINCT v.patient_id,9,MAX(v.start_date)
	FROM isanteplus.patient_visit v,openmrs.encounter enc,
	openmrs.encounter_type entype
	WHERE v.visit_id=enc.visit_id
	AND enc.encounter_type=entype.encounter_type_id
	AND (DATE(now()) > v.next_visit_date)
	AND enc.patient_id 
	NOT IN(SELECT dreason.patient_id FROM discontinuation_reason dreason
	WHERE dreason.reason IN(159,5240,159492))
	AND enc.patient_id IN (SELECT parv.patient_id 
	FROM isanteplus.patient_on_arv parv)
	GROUP BY v.patient_id
	UNION ALL
	SELECT DISTINCT pdis.patient_id,9,MAX(DATE(pdis.visit_date))
	FROM isanteplus.patient_dispensing pdis,openmrs.encounter enc,
	openmrs.encounter_type entype
	WHERE pdis.visit_id=enc.visit_id
	AND enc.encounter_type=entype.encounter_type_id
	AND (DATEDIFF(DATE(now()),pdis.next_dispensation_date)>90)
	AND enc.patient_id 
	NOT IN(SELECT dreason.patient_id FROM discontinuation_reason dreason
	WHERE dreason.reason IN(159,5240,159492))
	AND enc.patient_id IN (SELECT parv.patient_id 
	FROM isanteplus.patient_on_arv parv)
	GROUP BY pdis.patient_id;
	
/*INSERTION for patient status Recent on PRE-ART=7,
     Perdus de vue en Pré-ARV=10,Actifs en Pré-ARV=11 */
REPLACE INTO patient_status_ARV(patient_id,id_status,start_date)
	SELECT DISTINCT v.patient_id,
	CASE WHEN 
		(TIMESTAMPDIFF(MONTH,v.date_started,DATE(now()))<=12)
		AND (entype.uuid IN('17536ba6-dd7c-4f58-8014-08c7cb798ac7',
		'349ae0b4-65c1-4122-aa06-480f186c8350')) THEN 7
		WHEN
		(TIMESTAMPDIFF(MONTH, v.date_started,DATE(now()))>12)
		AND (entype.uuid NOT IN('17536ba6-dd7c-4f58-8014-08c7cb798ac7',
		'349ae0b4-65c1-4122-aa06-480f186c8350',
		'204ad066-c5c2-4229-9a62-644bc5617ca2',
		'33491314-c352-42d0-bd5d-a9d0bffc9bf1',
		'10d73929-54b6-4d18-a647-8b7316bc1ae3',
		'a9392241-109f-4d67-885b-57cc4b8c638f',
		'f037e97b-471e-4898-a07c-b8e169e0ddc4')) THEN 10
	   WHEN 
	   (TIMESTAMPDIFF(MONTH, v.date_started,DATE(now()))<=12) 
		AND (entype.uuid NOT IN('204ad066-c5c2-4229-9a62-644bc5617ca2',
		'33491314-c352-42d0-bd5d-a9d0bffc9bf1',
		'10d73929-54b6-4d18-a647-8b7316bc1ae3',
		'a9392241-109f-4d67-885b-57cc4b8c638f',
		'f037e97b-471e-4898-a07c-b8e169e0ddc4')) THEN 11
	END,
	MAX(v.date_started)
	FROM isanteplus.patient ispat,
	openmrs.visit v,openmrs.encounter enc,
	openmrs.encounter_type entype,openmrs.obs ob
	WHERE ispat.patient_id=v.patient_id
	AND v.visit_id=enc.visit_id 
	AND enc.encounter_type=entype.encounter_type_id
	AND enc.patient_id NOT IN 
	(SELECT dreason.patient_id FROM discontinuation_reason dreason
	WHERE dreason.reason IN(159,159492))
	AND ispat.vih_status=1
	AND ispat.patient_id NOT IN (SELECT parv.patient_id 
	FROM isanteplus.patient_on_arv parv)
	GROUP BY ispat.patient_id;
	
	/*UPDATE Discontinuations reason in table patient_status_ARV*/
	UPDATE patient_status_ARV psarv,discontinuation_reason dreason
	       SET psarv.dis_reason=dreason.reason
		   WHERE psarv.patient_id=dreason.patient_id
		   AND psarv.start_date=dreason.visit_date;				  
/*End of patient Status*/
/*Starting patient_prescription*/
	/*Insert for patient_id,encounter_id, drug_id areas*/
  REPLACE into patient_prescription
					(
					 patient_id,
					 encounter_id,
					 location_id,
					 drug_id
					)
					select distinct ob.person_id,
					ob.encounter_id,ob.location_id,ob.value_coded
					from openmrs.obs ob, openmrs.obs ob1
					where ob.person_id=ob1.person_id
					AND ob.encounter_id=ob1.encounter_id
					AND ob.obs_group_id=ob1.obs_id
                    AND ob1.concept_id=1442	
					AND ob.concept_id=1282;
	/*update provider for patient_prescription*/
	update patient_prescription pp, openmrs.encounter_provider enp
	set pp.provider_id=enp.provider_id
	WHERE pp.encounter_id=enp.encounter_id;
	  /*update visit_id, visit_date for table patient_prescription*/
	update patient_prescription patp, openmrs.visit vi, openmrs.encounter en
   set patp.visit_id=vi.visit_id, patp.visit_date=vi.date_started
	where patp.encounter_id=en.encounter_id
	AND en.visit_id=vi.visit_id;
	/*update rx_or_prophy for table patient_prescription*/
	update isanteplus.patient_prescription pp, openmrs.obs ob1, openmrs.obs ob2
		   set pp.rx_or_prophy=ob2.value_coded
		   WHERE pp.encounter_id=ob2.encounter_id
		   AND ob1.obs_id=ob2.obs_group_id
		   AND ob1.concept_id=1442
		   AND ob2.concept_id=160742;
    /*update posology_day for table patient_prescription*/
	update isanteplus.patient_prescription pp, openmrs.obs ob1, openmrs.obs ob2
		   set pp.posology=ob2.value_text
		   WHERE pp.encounter_id=ob2.encounter_id
		   AND ob1.obs_id=ob2.obs_group_id
		   AND ob1.concept_id=1442
		   AND ob2.concept_id=1444;
	/*update number_day for table patient_prescription*/
	update isanteplus.patient_prescription pp, openmrs.obs ob1, openmrs.obs ob2
		   set pp.number_day=ob2.value_numeric
		   WHERE pp.encounter_id=ob2.encounter_id
		   AND ob1.obs_id=ob2.obs_group_id
		   AND ob1.concept_id=1442
		   AND ob2.concept_id=159368;
/*End of patient_prescription*/	
/*Starting patient_laboratory */
/*Insertion for patient_laboratory*/
	REPLACE into patient_laboratory
					(
					 patient_id,
					 encounter_id,
					 location_id,
					 test_id
					)
					select distinct ob.person_id,
					ob.encounter_id,ob.location_id,ob.value_coded
					from openmrs.obs ob, openmrs.encounter enc, 
					openmrs.encounter_type entype
					where ob.encounter_id=enc.encounter_id
					AND enc.encounter_type=entype.encounter_type_id
                    AND ob.concept_id=1271
					AND entype.uuid='f037e97b-471e-4898-a07c-b8e169e0ddc4';	
    /*update provider for patient_laboratory*/
	update patient_laboratory lab, openmrs.encounter_provider enp
	set lab.provider_id=enp.provider_id
	WHERE lab.encounter_id=enp.encounter_id;
	/*update visit_id, visit_date for table patient_laboratory*/
	update patient_laboratory lab, openmrs.visit vi, openmrs.encounter en
    set lab.visit_id=vi.visit_id, lab.visit_date=vi.date_started
	where lab.encounter_id=en.encounter_id
	AND en.visit_id=vi.visit_id;
	/*update test_done,date_test_done,comment_test_done for patient_laboratory*/
	update patient_laboratory plab,openmrs.obs ob
	SET plab.test_done=1,plab.test_result=CASE WHEN ob.value_coded<>''
	   THEN ob.value_coded
	   WHEN ob.value_numeric<>'' THEN ob.value_numeric
	   WHEN ob.value_text<>'' THEN ob.value_text
	   END,
	plab.date_test_done=ob.obs_datetime,
	plab.comment_test_done=ob.comments
	WHERE plab.test_id=ob.concept_id
	AND plab.encounter_id=ob.encounter_id;

/*End of patient_laboratory*/			  
			SET FOREIGN_KEY_CHECKS=1;	  
		    SET SQL_SAFE_UPDATES = 1;
		 /*End of DML queries*/
	    END$$
DELIMITER ;


    DROP EVENT if exists isanteplusreports_dml_event;
	CREATE EVENT if not exists isanteplusreports_dml_event
	ON SCHEDULE  EVERY 30 MINUTE
	 STARTS now()
		DO
		call isanteplusreports_dml();