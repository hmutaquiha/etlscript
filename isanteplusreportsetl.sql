create database if not exists isanteplus;
SET GLOBAL event_scheduler = 1 ;
use isanteplus;
DROP TABLE if exists `patient_visit`;
DROP TABLE if exists `patient`;
CREATE TABLE if not exists `patient` (
  `location_id` int(11) DEFAULT NULL,
  `st_id` varchar(20) DEFAULT NULL,
  `national_id` varchar(20) DEFAULT NULL,
  `patient_id` int(11) NOT NULL,
  `given_name` longtext,
  `family_name` longtext,
  `gender` varchar(10) DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `telephone` varchar(15) DEFAULT NULL,
  `last_address` longtext,
  `degree` longtext,
  `vih_status` int(11) DEFAULT 0,
  `mother_name` longtext,
  `occupation` longtext,
  `maritalStatus` varchar(20) DEFAULT NULL,
  `place_of_birth` longtext,
  `creator` varchar(20) DEFAULT NULL,
  `date_created` date DEFAULT NULL,
  `death_date` date DEFAULT NULL,
  `cause_of_death` longtext,
  `last_inserted_date` datetime DEFAULT NULL,
  `last_updated_date` datetime DEFAULT NULL,
  PRIMARY KEY (`patient_id`),
  KEY `location_id` (`location_id`),
  CONSTRAINT `patient_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES openmrs.`location`(`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE  if not exists `patient_visit` (
  `visit_date` date DEFAULT NULL,
  `visit_id` int(11) DEFAULT NULL,
  `encounter_id` int(11) DEFAULT NULL,
  `location_id` int(11) DEFAULT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `stop_date` date DEFAULT NULL,
  `creator` varchar(20) DEFAULT NULL,
  `encounter_type` int(11) DEFAULT NULL,
  `form_id` int(11) DEFAULT NULL,
  `next_visit_date` date DEFAULT NULL,
  `last_insert_date` date DEFAULT NULL,
  KEY `location_id` (`location_id`),
  KEY `form_id` (`form_id`),
  KEY `patient_id` (`patient_id`),
  KEY `visit_id` (`visit_id`),
  KEY `patient_visit_ibfk_3_idx` (`patient_id`),
  CONSTRAINT `pk_visit` PRIMARY KEY(patient_id,visit_id),
  CONSTRAINT `patient_visit_ibfk_3` FOREIGN KEY (`patient_id`) REFERENCES openmrs.`patient`(`patient_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `patient_visit_ibfk_2` FOREIGN KEY (`form_id`) REFERENCES openmrs.`form`(`form_id`),
  CONSTRAINT `patient_visit_ibfk_4` FOREIGN KEY (`location_id`) REFERENCES openmrs.`location`(`location_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* insert data to patient table */
DROP EVENT if exists patient_insertion;
CREATE EVENT if not exists patient_insertion
    ON SCHEDULE  EVERY 2 MINUTE
	 STARTS now()
	DO
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
DROP EVENT if exists st_identifier_insertion;
CREATE EVENT if not exists st_identifier_insertion
    ON SCHEDULE  EVERY 2 MINUTE
	 STARTS now()
	DO
update patient p,openmrs.patient_identifier pi set p.st_id=pi.identifier 
where p.patient_id=pi.patient_id and identifier_type=1;

DROP EVENT if exists national_identifier_insertion;
CREATE EVENT if not exists national_identifier_insertion
    ON SCHEDULE  EVERY 2 MINUTE
	 STARTS now()
	DO
update patient p,openmrs.patient_identifier pi set p.national_id=pi.identifier 
where p.patient_id=pi.patient_id and identifier_type=2;

/* update patient with person attribute */
DROP EVENT if exists patient_attribute_insertion;
CREATE EVENT if not exists patient_attribute_insertion
    ON SCHEDULE  EVERY 2 MINUTE
	 STARTS now()
	DO
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
DROP EVENT if exists vih_status_insertion;
CREATE EVENT if not exists vih_status_insertion
    ON SCHEDULE  EVERY 2 MINUTE
	 STARTS now()
	DO
UPDATE patient p, openmrs.encounter en, openmrs.encounter_type ent
SET p.vih_status=1
WHERE p.patient_id=en.patient_id AND en.encounter_type=ent.encounter_type_id
AND (ent.uuid='17536ba6-dd7c-4f58-8014-08c7cb798ac7'
 OR ent.uuid='204ad066-c5c2-4229-9a62-644bc5617ca2'
 OR ent.uuid='349ae0b4-65c1-4122-aa06-480f186c8350'
 OR ent.uuid='33491314-c352-42d0-bd5d-a9d0bffc9bf1');

/* update patient with death information */


/* insert data to patient_visit table */
DROP EVENT if exists visit_insertion;
CREATE EVENT if not exists visit_insertion
    ON SCHEDULE  EVERY 2 MINUTE
	 STARTS now()
	DO
REPLACE INTO patient_visit
(visit_date,visit_id,encounter_id,location_id,
 patient_id,start_date,stop_date,creator,
 encounter_type,form_id,next_visit_date,
last_insert_date)
select e.encounter_datetime as visit_date,
       v.visit_id,e.encounter_id,v.location_id,
       v.patient_id,v.date_started,v.date_stopped,
       v.creator,e.encounter_type,e.form_id,o.value_datetime as next_visit_date,
       now() as last_insert_date
from openmrs.visit v,openmrs.encounter e,openmrs.obs o
where v.visit_id=e.visit_id and v.patient_id=e.patient_id
      and o.person_id=e.patient_id and o.encounter_id=e.encounter_id
      and o.concept_id='5096';




