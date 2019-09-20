DROP DATABASE if exists isanteplus; 
create database if not exists isanteplus;
SET GLOBAL event_scheduler = 1 ;
SET innodb_lock_wait_timeout = 250;
use isanteplus;
CREATE TABLE if not exists `patient` (
  `identifier` varchar(50) DEFAULT NULL,
  `st_id` varchar(50) DEFAULT NULL,
  `national_id` varchar(50) DEFAULT NULL,
  `patient_id` int(11) NOT NULL,
  `location_id` int(11) DEFAULT NULL,
  `given_name` longtext,
  `family_name` longtext,
  `gender` varchar(10) DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `telephone` varchar(50) DEFAULT NULL,
  `last_address` longtext,
  `degree` longtext,
  `vih_status` int(11) DEFAULT 0,
  `arv_status` int(11),
  `mother_name` longtext,
  `occupation` int(11),
  `maritalStatus` int(11),
  `place_of_birth` longtext,
  `creator` varchar(20) DEFAULT NULL,
  `date_created` date DEFAULT NULL,
  `death_date` date DEFAULT NULL,
  `cause_of_death` longtext,
  `first_visit_date` DATETIME,
  `last_visit_date` DATETIME,
  `date_started_arv` DATETIME,
  `next_visit_date` DATE,
  `last_inserted_date` datetime DEFAULT NULL,
  `last_updated_date` datetime DEFAULT NULL,
  PRIMARY KEY (`patient_id`),
  KEY `location_id` (`location_id`),
  CONSTRAINT `patient_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES openmrs.`location`(`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE  if not exists `patient_visit` (
  `visit_date` date DEFAULT NULL,
  `visit_id` int(11),
  `encounter_id` int(11) DEFAULT NULL,
  `location_id` int(11) DEFAULT NULL,
  `patient_id` int(11),
  `start_date` date DEFAULT NULL,
  `stop_date` date DEFAULT NULL,
  `creator` varchar(20) DEFAULT NULL,
  `encounter_type` int(11) DEFAULT NULL,
  `form_id` int(11) DEFAULT NULL,
  `next_visit_date` date DEFAULT NULL,
  `last_insert_date` date DEFAULT NULL,
  last_updated_date DATETIME,
  KEY `location_id` (`location_id`),
  KEY `form_id` (`form_id`),
  KEY `patient_id` (`patient_id`),
  KEY `visit_id` (`visit_id`),
  KEY `patient_visit_ibfk_3_idx` (`patient_id`),
  CONSTRAINT `pk_visit` PRIMARY KEY(patient_id, encounter_id, location_id),
  CONSTRAINT `patient_visit_ibfk_3` FOREIGN KEY (`patient_id`) REFERENCES openmrs.`patient`(`patient_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `patient_visit_ibfk_2` FOREIGN KEY (`form_id`) REFERENCES openmrs.`form`(`form_id`),
  CONSTRAINT `patient_visit_ibfk_4` FOREIGN KEY (`location_id`) REFERENCES openmrs.`location`(`location_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Debut etl for tb reports*/

CREATE TABLE IF NOT EXISTS patient_tb_diagnosis (
	patient_id int(11) not null,
	provider_id int(11),
	location_id int(11),
	visit_id int(11),
	visit_date Datetime,
	encounter_id INT(11) not null,
	tb_diag int(11),
	mdr_tb_diag int(11),
	tb_new_diag int(11),
	tb_follow_up_diag int(11),
	cough_for_2wks_or_more INT(11),
	tb_pulmonaire INT(11),
	tb_multiresistante INT(11),
	tb_extrapul_ou_diss INT(11),
	tb_treatment_start_date DATE,
	status_tb_treatment INT(11) default 0,
	/*statuts_tb_treatment = Gueri(1),traitement_termine(2),
		Abandon(3),tranfere(4),decede(5), Actif(6)
	*/
	tb_treatment_stop_date DATE,
	last_updated_date DATETIME,
	PRIMARY KEY (`encounter_id`,location_id),
	CONSTRAINT FOREIGN KEY (patient_id) REFERENCES isanteplus.patient(patient_id),
	INDEX(visit_date),
	INDEX(encounter_id),
	INDEX(patient_id)
);
/*Table patient_dispensing for all drugs from the form ordonance medical*/

CREATE TABLE IF NOT EXISTS patient_dispensing (
	patient_id int(11) not null,
	visit_id int(11),
	location_id int(11),
	visit_date Datetime,
	encounter_id int(11) not null,
	provider_id int(11),
	drug_id int(11) not null,
	dose_day int(11),
	pills_amount int(11),
	dispensation_date date,
	next_dispensation_date Date,
	dispensation_location int(11) default 0,
	arv_drug int(11) default 1066, /*1066=No, 1065=YES*/
	rx_or_prophy int(11),
	last_updated_date DATETIME,
	CONSTRAINT pk_patient_dispensing PRIMARY KEY(encounter_id,location_id,drug_id),
    /*CONSTRAINT FOREIGN KEY (patient_id) REFERENCES isanteplus.patient(patient_id),*/
	INDEX(visit_date),
	INDEX(encounter_id),
	INDEX(patient_id)	
);
/*Table patient_imagerie*/

CREATE TABLE IF NOT EXISTS patient_imagerie (
	patient_id int(11) not null,
	location_id int(11),
	visit_id int(11) not null,
	encounter_id int(11) not null,
	visit_date Datetime,
	radiographie_pul int(11) default 0,
	radiographie_autre int(11),
	crachat_barr int(11),
	last_updated_date DATETIME,
	PRIMARY KEY (`location_id`,`encounter_id`),
	CONSTRAINT FOREIGN KEY (patient_id) REFERENCES isanteplus.patient(patient_id),
	INDEX(visit_date),
	INDEX(encounter_id),
	INDEX(patient_id)
);
/*Table that contains all the arv drugs*/
DROP TABLE if exists `arv_drugs`;
CREATE TABLE IF NOT EXISTS arv_drugs(
	id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
	drug_id INT(11) NOT NULL UNIQUE,
	drug_name longtext NOT NULL,
	date_inserted DATE NOT NULL
);
TRUNCATE TABLE arv_drugs;
INSERT INTO arv_drugs(drug_id,drug_name,date_inserted)
VALUES(70056,'Abacavir(ABC)', DATE(now())),
	  (630,'Combivir(AZT+3TC)', DATE(now())),
	  (74807,'Didanosine(ddI)', DATE(now())),
	  (75628,'Emtricitabine(FTC)', DATE(now())),
	  (78643,'Lamivudine(3TC)', DATE(now())),
	  (84309,'Stavudine(d4T)', DATE(now())),
	  (84795,'Tenofovir(TDF)', DATE(now())),
	  (817,'Trizivir(ABC+AZT+3TC)', DATE(now())),
	  (86663,'Zidovudine(AZT)', DATE(now())),
	  (75523,'Efavirenz(EFV)', DATE(now())),
	  (80586,'Nevirapine(NVP)', DATE(now())),
	  (71647,'Atazanavir(ATV)', DATE(now())),
	  (159809,'Atazanavir+BostRTV', DATE(now())),
	  (77995,'Indinavir(IDV)', DATE(now())),
	  (794,'Lopinavir + BostRTV(Kaletra)', DATE(now())),
	  (74258,'Darunavir', DATE(now())),
	  (154378,'Raltegravir', DATE(now())),
	  (165085,'Dolutegravir(DTG)', DATE(now())),
	  (165093,'Elviltegravir(EVG)', DATE(now())),
	  (80487,'Nelfinavir (NFV)', DATE(now())),
	  (159810,'Etravirine(ETV)', DATE(now())),
	  (83690,'Saquinavir (SQV)', DATE(now()));

/*Table that contains the labels of ARV status*/
DROP TABLE IF EXISTS arv_status_loockup;
	CREATE TABLE IF NOT EXISTS arv_status_loockup(
	id int primary key auto_increment,
	name_en varchar(50),
	name_fr varchar(50),
	definition longtext,
	insertDate date);

	insert into arv_status_loockup values 
	(1,'Death on ART','Décédés','Tout patient mis sous ARV et ayant un rapport d’arrêt rempli pour motif de décès',date(now())),
	(2,'Stopped','Arrêtés','Tout patient mis sous ARV et ayant un rapport d’arrêt rempli pour motif d’arrêt de traitement',date(now())),
	(3,'Transfert','Transférés','Tout patient mis sous ARV et ayant un rapport d’arrêt rempli pour motif de transfert',date(now())),
	(4,'Died during the transition period','Décédé durant la période de transition',' Tout patient VIH+ non encore mis sous ARV ayant un rapport d’arrêt rempli pour cause de décès',date(now())),
	(5,'Transferred during the transition period','Transféré durant la période de transition','Tout patient VIH+ non encore mis sous ARV ayant un rapport d’arrêt rempli pour cause de transfert',date(now())),
	(6,'Regular','Réguliers (actifs sous ARV)','Tout patient mis sous ARV et n’ayant aucun rapport d’arrêt rempli pour motifs de décès, de transfert, ni d’arrêt de traitement. La date de prochain rendez-vous clinique ou de prochaine collecte de médicaments est située dans le futur de la période d’analyse. (Fiches à ne pas considérer, labo et counseling)',date(now())),
	(7,'Recent during the transition period','Récent durant la période de transition','Tout patient VIH+ non encore mis sous ARV ayant eu sa première visite (clinique « 1re visite VIH» ) au cours des 12 derniers mois tout en excluant tout patient ayant un rapport d’arrêt avec motifs décédé ou transféré',date(now())),
	(8,'Missing appointment','Rendez-vous ratés','Tout patient mis sous ARV et n’ayant aucun rapport d’arrêt rempli pour motifs de décès, de transfert, ni d’arrêt de traitement. La date de la période d’analyse est supérieure à la date de rendez-vous clinique ou de collecte de médicaments la plus récente sans excéder 30 jours',date(now())),
	(9,'Lost to follow-up','Perdus de vue','Tout patient mis sous ARV et n’ayant aucun rapport d’arrêt rempli pour motifs de décès, de transfert, ni d’arrêt de traitement. La date de la période d’analyse est supérieure à la date de rendez-vous clinique ou de collecte de médicaments la plus récente de plus de 30 jours',date(now())),
	(10,'Lost of follow up during the transition period','Perdu de vue durant la période de transition','Tout patient VIH+ non encore mis sous ARV n’ayant eu aucune visite (clinique « 1re visite VIH et suivi VIH uniquement », pharmacie, labo) au cours des 12 derniers mois et n’étant ni décédé ni transféré',date(now())),
	(11,'Active during the transition period','Actif durant  la période de transition','Tout patient VIH+ non encore mis sous ARV et ayant eu une visite (clinique de suivi VIH uniquement, ou de pharmacie ou de labo) au cours des 12 derniers mois et n’étant ni décédé ni transféré',date(now())),
	(12,'ongoing','En cours','La somme des patients sous ARV réguliers et ceux ayant raté leurs rendez-vous',date(now()));
 /*Table that contains all patients on ARV*/
	DROP TABLE IF EXISTS patient_on_arv;
	create table if not exists patient_on_arv(
	patient_id int(11),
	visit_id int(11),
	visit_date date,
	last_updated_date DATETIME,
	CONSTRAINT pk_patient_on_arv PRIMARY KEY (patient_id) 
	);
/*Table for all patients with reason of discontinuation
Perte de contact avec le patient depuis plus de trois mois = 5240
Transfert vers un autre établissement=159492
Décès=159
Discontinuations=1667
Raison d'arrêt inconnue=1067
*/
 DROP TABLE IF EXISTS discontinuation_reason;
	create table if not exists discontinuation_reason(
	patient_id int(11),
	visit_id int(11),
	visit_date date,
	reason int(11),
	reason_name longtext,
	last_updated_date DATETIME,
	CONSTRAINT pk_dreason PRIMARY KEY (patient_id,visit_id,reason)
	);
/*Create a table for raison arretés concept_id = 1667, 
		answer_concept_id IN (1754,160415,115198,159737,5622)
		That table allow us to delete from the table discontinuation_reason
		WHERE the discontinuation_raison (arretés raison) not in Adhérence inadéquate=115198
		AND Préférence du patient=159737
		*/
	DROP TABLE IF EXISTS stopping_reason;
	create table if not exists stopping_reason(
	patient_id int(11),
	visit_id int(11),
	visit_date date,
	reason int(11),
	reason_name longtext,
	other_reason longtext,
	last_updated_date DATETIME,
	CONSTRAINT pk_stop_reason PRIMARY KEY (patient_id,visit_id,reason)
	);
/*Table patient_status_ARV contains all patients and their status*/
	DROP TABLE IF EXISTS patient_status_arv;
	create table if not exists patient_status_arv(
	patient_id int(11),
	id_status int,
	start_date date,
	end_date date,
	dis_reason int(11),
	last_updated_date DATETIME,
	CONSTRAINT pk_patient_status_arv PRIMARY KEY (patient_id,id_status,start_date)
	);
	
/*Create table for medicaments prescrits*/
DROP TABLE IF EXISTS patient_prescription;
CREATE TABLE IF NOT EXISTS patient_prescription (
	patient_id int(11) not null,
	visit_id int(11),
	location_id int(11),
	visit_date Datetime,
	encounter_id int(11) not null,
	provider_id int(11),
	drug_id int(11) not null,
	next_dispensation_date DATE,
	dispensation_location int(11) default 0, 
	arv_drug int(11) default 1066, /*1066=No, 1065=YES*/
	dispense int(11), /*1066=No, 1065=YES*/
	rx_or_prophy int(11),
    posology text,
    number_day int(11),	
	last_updated_date DATETIME,
	CONSTRAINT pk_patient_prescription PRIMARY KEY(encounter_id,location_id,drug_id),
	INDEX(visit_date),
	INDEX(encounter_id),
	INDEX(patient_id)	
);

 /*Create table for lab*/
	DROP TABLE IF EXISTS patient_laboratory;
	CREATE TABLE IF NOT EXISTS patient_laboratory(
		patient_id int(11) not null,
		visit_id int(11),
		location_id int(11),
		visit_date Datetime,
		encounter_id int(11) not null,
		provider_id int(11),
		test_id int(11) not null,
		test_done int(11) default 0,
		test_result text,
		date_test_done DATE,
		comment_test_done text,
		order_destination  varchar(50),
    	test_name text,
		last_updated_date DATETIME,
		CONSTRAINT pk_patient_laboratory PRIMARY KEY (patient_id,encounter_id,test_id),
		INDEX(visit_date),
		INDEX(encounter_id),
		INDEX(patient_id)	
	);
	
	DROP TABLE IF EXISTS patient_pregnancy;
	CREATE TABLE IF NOT EXISTS patient_pregnancy(
	patient_id int(11),
	encounter_id int(11),
	start_date date,
	end_date date,
	last_updated_date DATETIME,
	CONSTRAINT pk_patient_preg PRIMARY KEY (patient_id,encounter_id));
	
	/*Create table alert_lookup*/
	DROP TABLE IF EXISTS alert_lookup;
	CREATE TABLE IF NOT EXISTS alert_lookup(
		id int primary key auto_increment,
		libelle text,
		insert_date date
	);
	/*table alert_lookup insertion*/
	INSERT INTO alert_lookup(id,libelle,insert_date) VALUES 
	(1,'Nombre de patient sous ARV depuis 6 mois sans un résultat de charge virale',DATE(now())),
	(2,'Nombre de femmes enceintes, sous ARV depuis 4 mois sans un résultat de charge virale',DATE(now())),
	(3,'Nombre de patients ayant leur dernière charge virale remontant à au moins 12 mois',DATE(now())),
	(4,'Nombre de patients ayant leur dernière charge virale remontant à au moins 3 mois et dont le résultat était > 1000 copies/ml',DATE(now())),
	(5,'Patient avec une dernière charge viral >1000 copies/ml',DATE(now())),
	(6,'Tout patient dont la prochaine date de dispensation (next_disp) arrive dans les 30 
	prochains jours par rapport à la date de consultation actuelle',DATE(now())),
	(7,'Tout patient dont la prochaine date de dispensation (next_disp) se situe 
	dans le passe par rapport à la date de consultation actuelle',DATE(now())),
	(8,'Patients sous ARV depuis 5 mois sans un résultat de charge virale',DATE(now()));
	
	
	/*Create table alert*/
	DROP TABLE IF EXISTS alert;
	CREATE TABLE IF NOT EXISTS alert(
	id int primary key auto_increment,
	patient_id int(11),
	id_alert int(11),
	encounter_id int(11),
	date_alert date,
	last_updated_date DATETIME);
	
	/*TABLE patient_diagnosis, this table contains all patient diagnosis*/	
DROP TABLE IF EXISTS patient_diagnosis;
CREATE TABLE IF NOT EXISTS patient_diagnosis(
	patient_id int(11),
	encounter_id int(11),
	location_id int(11),
	encounter_date date,
	concept_group int(11),
	obs_group_id int(11),
	concept_id int(11),
	answer_concept_id int(11),
	suspected_confirmed int(11),
	primary_secondary int(11),
	last_updated_date DATETIME,
	constraint pk_patient_diagnosis 
	PRIMARY KEY (encounter_id,location_id,concept_group,concept_id,answer_concept_id)
);

/*Table visit_type for visit_type like : Gynécologique=160456,Prénatale=1622,
Postnatale=1623,Planification familiale=5483 (ex: OBGYN FORM) */
DROP TABLE IF EXISTS visit_type;
	CREATE TABLE IF NOT EXISTS visit_type(
	patient_id int(11),
	encounter_id int(11),
	location_id int(11),
	visit_id int(11),
	obs_group int(11),
	concept_id int(11),
	v_type int(11),
	encounter_date date,
	last_updated_date DATETIME,
	CONSTRAINT pk_isanteplus_visit_type 
	PRIMARY KEY (encounter_id,location_id,obs_group,concept_id,v_type));

/*Create table virological_tests */
DROP TABLE IF EXISTS virological_tests;
 CREATE TABLE IF NOT EXISTS virological_tests(
	patient_id int(11),
	encounter_id int(11),
	location_id int(11),
	encounter_date date,
	concept_group int(11),
	obs_group_id int(11),
    test_id int(11),
	answer_concept_id int(11),
	test_result int(11),
	age int(11),
	age_unit int(11),
	test_date date,
	last_updated_date DATETIME,
	constraint pk_virological_tests PRIMARY KEY (encounter_id,location_id,obs_group_id,test_id));
	
/* Create patient_delivery table */
DROP TABLE IF EXISTS patient_delivery;
CREATE TABLE IF NOT EXISTS patient_delivery(
	patient_id int(11),
	encounter_id int(11),
	location_id int(11),
	delivery_date datetime,
	delivery_location int(11),
	vaginal int(11),
	forceps int(11),
	vacuum int(11),
	delivrance int(11),
	encounter_date date,
	last_updated_date DATETIME,
	constraint pk_patient_delivery PRIMARY KEY (encounter_id,location_id));
/*Create table pediatric_first_visit*/		   
	DROP TABLE IF EXISTS pediatric_hiv_visit;
	CREATE TABLE IF NOT EXISTS pediatric_hiv_visit(
	patient_id int(11),
	encounter_id int(11),
	location_id int(11),
	ptme int(11),
	prophylaxie72h int(11),
	actual_vih_status int(11),
	encounter_date date,
	constraint pk_pediatric_hiv_visit PRIMARY KEY (patient_id,encounter_id,location_id));
	
	/*Create table patient_menstruation*/		   
	DROP TABLE IF EXISTS patient_menstruation;
	CREATE TABLE IF NOT EXISTS patient_menstruation(
	patient_id int(11),
	encounter_id int(11),
	location_id int(11),
	duree_regle int(11),
	duree_cycle int(11),
	ddr date,
	encounter_date date,
	last_updated_date DATETIME,
	constraint pk_patient_menstruation PRIMARY KEY (patient_id,encounter_id,location_id));
	
	/*Create table for vih_risk_factor*/
	DROP TABLE IF EXISTS vih_risk_factor;
	CREATE TABLE IF NOT EXISTS vih_risk_factor(
	patient_id int(11),
	encounter_id int(11),
	location_id int(11),
	risk_factor int(11),
	encounter_date date,
	last_updated_date DATETIME,
	constraint pk_vih_risk_factor PRIMARY KEY (patient_id,encounter_id,location_id,risk_factor));

	/*Create table for vaccinations*/
	DROP TABLE IF EXISTS vaccination;
	CREATE TABLE IF NOT EXISTS vaccination(
	patient_id int(11),
	encounter_id int(11),
	encounter_date date,
	location_id int(11),
	age_range int(11),
	vaccination_done boolean DEFAULT false,
	constraint pk_vaccination PRIMARY KEY (patient_id,encounter_id,location_id));

	/*Create table for health qual visits*/
	DROP TABLE IF EXISTS health_qual_patient_visit;
	CREATE TABLE IF NOT EXISTS health_qual_patient_visit(
	patient_id int(11),
	encounter_id int(11),
	visit_date date,
	visit_id int(11),
	location_id int(11),
	encounter_type int(11) DEFAULT NULL,
	patient_bmi double DEFAULT NULL,
	adherence_evaluation int(11) DEFAULT NULL,
	family_planning_method_used boolean DEFAULT false,
	evaluated_of_tb boolean DEFAULT false,
	nutritional_assessment_completed boolean DEFAULT false,
	is_active_tb boolean DEFAULT false,
	age_in_years int(11),
	last_insert_date date DEFAULT NULL,
	last_updated_date DATETIME,
	constraint pk_health_qual_patient_visit PRIMARY KEY (patient_id, encounter_id, location_id));
	/*Eposed infants table
		
	*/
	DROP TABLE IF EXISTS exposed_infants;
	CREATE table IF NOT EXISTS exposed_infants(
		patient_id int(11),
		location_id int(11),
		encounter_id int(11),
		visit_date date,
		condition_exposee int(11)
	);
	/*serological_tests table*/
	DROP TABLE IF EXISTS serological_tests;
 CREATE TABLE IF NOT EXISTS serological_tests(
	patient_id int(11),
	encounter_id int(11),
	location_id int(11),
	encounter_date date,
	concept_group int(11),
	obs_group_id int(11),
    test_id int(11),
	answer_concept_id int(11),
	test_result int(11),
	age int(11),
	age_unit int(11),
	test_date date,
	last_updated_date DATETIME,
	constraint pk_serological_tests PRIMARY KEY (encounter_id,location_id,obs_group_id,test_id));
	
	/*Create table patient_pcr*/
	DROP TABLE IF EXISTS patient_pcr;
	CREATE TABLE IF NOT EXISTS patient_pcr(
		patient_id int(11),
		encounter_id int(11),
		location_id int(11),
		visit_date date,
		pcr_result int(11),
		test_date date,
		last_updated_date DATETIME
	);
	
	
	DROP TABLE if exists regimen;
CREATE TABLE regimen
(
	regID INT(11) PRIMARY KEY,
	regimenName VARCHAR(255),
	drugID1 INT(11),
	drugID2 INT(11),
	drugID3 INT(11),
	shortName VARCHAR(255) NOT NULL,
	regGroup VARCHAR(255)
);

CREATE TABLE if not exists pepfarTable (
	location_id INT(11),
	patient_id INT(11),
	visit_date DATE, 
	regimen VARCHAR(255),
	rx_or_prophy INT(11),
	last_updated_date DATETIME,
	CONSTRAINT pk_pepfarTable_primary_key PRIMARY KEY (location_id, patient_id, visit_date, regimen)
	);

/*table for malaria survaillance*/
DROP TABLE if exists patient_malaria;
CREATE TABLE patient_malaria (
	patient_id int(11) not null,
	location_id int(11),
	visit_id int(11) not null,
	visit_date Datetime,
	encounter_id INT(11) not null,
	encounter_type_id int(11) not null,
	fever_for_less_than_2wks int(11),
	chloroquine_duration int(11),
	primanique_duration int(11),
	quinine_duration int(11),
	chloroquine_received tinyint(1),
	primanique_received tinyint(1),
	quinine_received tinyint(1),
	malaria_test int(11),
	test_result INT(11),
	rapid_test_result INT(11),
	last_updated_date DATETIME,
	voided TINYINT(1),
	PRIMARY KEY (`encounter_id`,location_id),
	CONSTRAINT FOREIGN KEY (patient_id) REFERENCES isanteplus.patient(patient_id),
	INDEX(visit_date),
	INDEX(encounter_id),
	INDEX(patient_id)
);
	
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(1,'1stReg1',84309,78643,80586,'d4T-3TC-NVP','1stReg1');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(2,'1stReg2',84309,78643,75523,'d4T-3TC-EFV','1stReg2');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(3,'1stReg3a',86663,78643,80586,'ZDV-3TC-NVP','1stReg3');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(5,'1stReg4a',86663,78643,75523,'ZDV-3TC-EFV','1stReg4');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(7,'2ndAdult1',86663,74807,794,'ZDV-ddI-LPV/r','2ndAdult1');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(8,'2ndAdult2',84309,74807,794,'d4T-ddI-LPV/r','2ndAdult2');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(9,'2ndChild1',84309,74807,80487,'d4T-ddI-NFV','2ndChild1');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(10,'1stReg8a',817,'0','0','ZDV-3TC-ABC','1stReg8');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(11,'2ndAdult3',86663,74807,77995,'ZDV-ddI-IDV','2ndAdult3');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(12,'2ndAdult4',86663,74807,80487,'ZDV-ddI-NFV','2ndAdult4');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(13,'1stReg7',84795,75628,75523,'FTC-TNF-EFV','1stReg7');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(14,'1stReg8b',86663,78643,70056,'ZDV-3TC-ABC','1stReg8');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(15,'1stReg8c',630,70056,'0','ZDV-3TC-ABC','1stReg8');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(16,'1stReg9',70056,74807,75628,'ABC-ddI-FTC','1stReg9');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(17,'1stReg10',70056,74807,78643,'ABC-ddI-3TC','1stReg10');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(18,'1stReg11',70056,74807,84309,'ABC-ddI-d4T','1stReg11');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(19,'1stReg12',70056,74807,86663,'ABC-ddI-ZDV','1stReg12');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(20,'1stReg13',70056,74807,84795,'ABC-ddI-TNF','1stReg13');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(21,'1stReg14',70056,74807,75523,'ABC-ddI-EFV','1stReg14');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(22,'1stReg15',70056,74807,80586,'ABC-ddI-NVP','1stReg15');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(23,'1stReg16',70056,75628,78643,'ABC-FTC-3TC','1stReg16');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(24,'1stReg17',70056,75628,84309,'ABC-FTC-d4T','1stReg17');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(25,'1stReg18',70056,75628,84795,'ABC-FTC-TNF','1stReg18');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(26,'1stReg19',70056,75628,86663,'ABC-FTC-ZDV','1stReg19');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(27,'1stReg20',70056,75628,75523,'ABC-FTC-EFV','1stReg20');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(28,'1stReg21',70056,75628,80586,'ABC-FTC-NVP','1stReg21');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(29,'1stReg22',70056,78643,84309,'ABC-3TC-d4T','1stReg22');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(30,'1stReg23',70056,78643,84795,'ABC-3TC-TNF','1stReg23');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(31,'1stReg24',70056,78643,75523,'ABC-3TC-EFV','1stReg24');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(32,'1stReg25',70056,78643,80586,'ABC-3TC-NVP','1stReg25');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(33,'1stReg26',70056,84309,84795,'ABC-d4T-TNF','1stReg26');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(34,'1stReg27',70056,84309,86663,'ABC-d4T-ZDV','1stReg27');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(35,'1stReg28',70056,84309,75523,'ABC-d4T-EFV','1stReg28');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(36,'1stReg29',70056,84309,80586,'ABC-d4T-NVP','1stReg29');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(37,'1stReg30',70056,84795,86663,'ABC-TNF-ZDV','1stReg30');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(38,'1stReg31',70056,84795,75523,'ABC-TNF-EFV','1stReg31');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(39,'1stReg32',70056,84795,80586,'ABC-TNF-NVP','1stReg32');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(40,'1stReg33',70056,86663,75523,'ABC-ZDV-EFV','1stReg33');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(41,'1stReg34',70056,86663,80586,'ABC-ZDV-NVP','1stReg34');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(42,'1stReg35a',86663,78643,74807,'ZDV-3TC-ddI','1stReg35');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(43,'1stReg36a',86663,78643,75628,'ZDV-3TC-FTC','1stReg36');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(44,'1stReg37a',86663,78643,84309,'ZDV-3TC-d4T','1stReg37');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(45,'1stReg38a',86663,78643,84795,'ZDV-3TC-TNF','1stReg38');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(46,'1stReg39',74807,75628,78643,'ddI-FTC-3TC','1stReg39');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(47,'1stReg40',74807,75628,84309,'ddI-FTC-d4T','1stReg40');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(48,'1stReg41',74807,75628,84795,'ddI-FTC-TNF','1stReg41');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(49,'1stReg42',74807,75628,86663,'ddI-FTC-ZDV','1stReg42');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(50,'1stReg43',74807,75628,75523,'ddI-FTC-EFV','1stReg43');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(51,'1stReg44',74807,75628,80586,'ddI-FTC-NVP','1stReg44');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(52,'1stReg45',74807,78643,84309,'ddI-3TC-d4T','1stReg45');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(53,'1stReg46',74807,78643,84795,'ddI-3TC-TNF','1stReg46');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(55,'1stReg48',74807,78643,75523,'ddI-3TC-EFV','1stReg48');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(56,'1stReg49',74807,78643,80586,'ddI-3TC-NVP','1stReg49');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(57,'1stReg50',74807,84309,84795,'ddI-d4T-TNF','1stReg50');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(58,'1stReg51',74807,84309,86663,'ddI-d4T-ZDV','1stReg51');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(59,'1stReg52',74807,84309,75523,'ddI-d4T-EFV','1stReg52');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(60,'1stReg53',74807,84309,80586,'ddI-d4T-NVP','1stReg53');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(61,'1stReg54',74807,84795,86663,'ddI-TNF-ZDV','1stReg54');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(62,'1stReg55',74807,84795,75523,'ddI-TNF-EFV','1stReg55');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(63,'1stReg56',74807,84795,80586,'ddI-TNF-NVP','1stReg56');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(64,'1stReg57',74807,86663,75523,'ddI-ZDV-EFV','1stReg57');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(65,'1stReg58',74807,86663,80586,'ddI-ZDV-NVP','1stReg58');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(66,'1stReg59',75628,78643,84309,'FTC-3TC-d4T','1stReg59');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(67,'1stReg60',75628,78643,84795,'FTC-3TC-TNF','1stReg60');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(69,'1stReg62',75628,78643,75523,'FTC-3TC-EFV','1stReg62');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(70,'1stReg63',75628,78643,80586,'FTC-3TC-NVP','1stReg63');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(71,'1stReg64',75628,84309,84795,'FTC-d4T-TNF','1stReg64');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(72,'1stReg65',75628,84309,86663,'FTC-d4T-ZDV','1stReg65');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(73,'1stReg66',75628,84309,75523,'FTC-d4T-EFV','1stReg66');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(74,'1stReg67',75628,84309,80586,'FTC-d4T-NVP','1stReg67');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(75,'1stReg68',75628,84795,86663,'FTC-TNF-ZDV','1stReg68');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(76,'1stReg69',75628,84795,80586,'FTC-TNF-NVP','1stReg69');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(77,'1stReg70',75628,86663,75523,'FTC-ZDV-EFV','1stReg70');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(78,'1stReg71',75628,86663,80586,'FTC-ZDV-NVP','1stReg71');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(79,'1stReg72',78643,84309,84795,'3TC-d4T-TNF','1stReg72');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(80,'1stReg73',78643,84795,75523,'3TC-TNF-EFV','1stReg73');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(81,'1stReg74',78643,84795,80586,'3TC-TNF-NVP','1stReg74');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(82,'1stReg75',84309,84795,86663,'d4T-TNF-ZDV','1stReg75');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(83,'1stReg76',84309,84795,75523,'d4T-TNF-EFV','1stReg76');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(84,'1stReg77',84309,84795,80586,'d4T-TNF-NVP','1stReg77');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(85,'1stReg78',84309,86663,75523,'d4T-ZDV-EFV','1stReg78');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(86,'1stReg79',84309,86663,80586,'d4T-ZDV-NVP','1stReg79');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(87,'1stReg80',84795,86663,75523,'TNF-ZDV-EFV','1stReg80');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(88,'1stReg81',84795,86663,80586,'TNF-ZDV-NVP','1stReg81');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(89,'2ndReg4',84795,75628,794,'TNF-FTC-LPV/r','2ndReg4');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(90,'2ndReg5a',86663,78643,794,'ZDV-3TC-LPV/r','2ndReg5');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(93,'2ndReg8',84309,78643,77995,'d4T-3TC-IDV','2ndReg8');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(94,'2ndReg9',84309,78643,794,'d4T-3TC-LPV/r','2ndReg9');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(95,'2ndReg10',84309,78643,80487,'d4T-3TC-NFV','2ndReg10');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(96,'2ndReg11',84309,74807,77995,'d4T-ddI-IDV','2ndReg11');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(98,'2ndReg13a',86663,78643,77995,'ZDV-3TC-IDV','2ndReg13');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(99,'2ndReg13b',630,77995,'0','ZDV-3TC-IDV','2ndReg13');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(54,'1stReg35b',630,74807,'0','ZDV-3TC-ddI','1stReg35');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(68,'1stReg36b',630,75628,'0','ZDV-3TC-FTC','1stReg36');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(91,'1stReg37b',630,84309,'0','ZDV-3TC-d4T','1stReg37');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(92,'1stReg38b',630,84795,'0','ZDV-3TC-TNF','1stReg38');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(97,'2ndReg5b',630,794,'0','ZDV-3TC-LPV/r','2ndReg5');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(100,'2nd2009-1',84795,78643,159809,'TNF-3TC-ATV/r','2nd2009-1');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(101,'2nd2009-2',84795,78643,794,'TNF-3TC-LPV/r','2nd2009-2');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(102,'2nd2009-3',84795,75628,159809,'TNF-FTC-ATV/r','2nd2009-3');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(103,'2nd2009-5',630,159809,'0','AZT-3TC-ATV/r','2nd2009-5');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(104,'2nd2009-5',86663,78643,159809,'AZT-3TC-ATV/r','2nd2009-5');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(105,'2nd2009-10',630,84795,159809,'AZT-TNF-3TC-ATV/r','2nd2009-10');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(106,'2nd2009-12',630,84795,794,'AZT-TNF-3TC-LPV/r','2nd2009-12');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(107,'2nd2016-1',84795,75628,74258,'TNF+FTC+DRV/r','2nd2016-1');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(108,'1stReg2016-2',630,80586,'0','AZT+3TC+NVP','1stReg2016');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(109,'2nd2016-3',84795,78643,74258,'TNF+3TC+DRV/r','2nd2016-3');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(110,'2nd2016-4',630,74258,'0','AZT+3TC+DRV/r','2nd2016-4');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(111,'2nd2016-5',630,794,'0','AZT+3TC+LPR/r','2nd2016-5');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(112,'1stReg2016-6',630,75523,'0','AZT+3TC+EFV','1stReg2016');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(113,'1stReg2016-7',70056,86663,78643,'ABC + AZT+3TC','1stReg2016');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(114,'2nd2016-8',74258,75523,154378,'DRV/r+EFV+RAL','2nd2016-8');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(115,'2nd',70056,78643,794,'ABC-3TC-LPV/r','2nd');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(116,'2nd',70056,78643,159809,'ABC-3TC-ATV/r','2nd');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(117,'1stReg',84795,78643,165085,'TNF-3TC-DTG','1stReg');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(118,'2nd',70056,78643,74258,'ABC-3TC-DRV/r','1stReg');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(119,'3rd',74258,165085,159810,'DRV-DTG-ETV','3rd');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(120,'1stReg',630,165085,'0','AZT-3TC-DTG','1stReg');
insert into regimen(regID,regimenName,drugID1,drugID2,drugID3,shortName,regGroup) values(121,'1stReg',70056,78643,165085,'ABC-3TC-DTG','1stReg');

CREATE TABLE IF NOT EXISTS `openmrs.isanteplus_patient_arv` (
  `patient_id` int(11) NOT NULL,
  `arv_status` varchar(255) DEFAULT NULL,
  `arv_regimen` varchar(255) DEFAULT NULL,
  `date_started_arv` date DEFAULT NULL,
  `next_visit_date` date DEFAULT NULL,
  `date_created` datetime NOT NULL,
  `date_changed` datetime DEFAULT NULL,
  PRIMARY KEY (`patient_id`),
  CONSTRAINT `isanteplus_patient_id_fk` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

	
GRANT SELECT ON isanteplus.* TO 'openmrs_user'@'localhost';


DELIMITER $$
	DROP PROCEDURE IF EXISTS isanteplus.set_scheduler_and_lock_wait_variable$$
	CREATE PROCEDURE isanteplus.set_scheduler_and_lock_wait_variable()
	BEGIN
			SET GLOBAL event_scheduler = 1 ;
			SET innodb_lock_wait_timeout = 250;
    
    END$$
	DELIMITER ;

GRANT EXECUTE ON PROCEDURE isanteplus.set_scheduler_and_lock_wait_variable TO 'openmrs_user'@'localhost';

/*Adding column voided for all the table*/
ALTER TABLE isanteplus.patient
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_visit
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_tb_diagnosis
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_dispensing
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_imagerie
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_on_arv
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_prescription
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_laboratory
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_pregnancy
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_diagnosis
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.visit_type
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.virological_tests
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_delivery
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.pediatric_hiv_visit
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_menstruation
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.vih_risk_factor
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.vaccination
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.health_qual_patient_visit
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.serological_tests
ADD COLUMN voided tinyint(1);

ALTER TABLE isanteplus.patient_status_arv
ADD COLUMN date_started_status datetime;

ALTER TABLE isanteplus.patient_status_arv
ADD COLUMN encounter_id INT(11) AFTER start_date;

ALTER TABLE isanteplus.patient_prescription
ADD COLUMN dispensation_date DATE AFTER drug_id;

ALTER TABLE isanteplus.patient_prescription
ADD COLUMN number_day_dispense INT(11) AFTER number_day;

ALTER TABLE isanteplus.patient_prescription
ADD COLUMN pills_amount_dispense INT(11) AFTER number_day_dispense;




