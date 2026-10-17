--liquibase formatted sql

--changeset ite4120:blood-04-retire-placeholder-questions
--comment Retire the placeholder readiness questions
/* The six questions of 90-demo-data.sql were placeholders from the group's
   notes. They are retired (soft delete), not edited: a released changeset is
   immutable. On a database without the demo context there is nothing to
   retire and this is a no-op. */
update blood.readiness_question
   set sys_status = 'C'
 where sys_status = 'A'
   and question_code in ('ATE', 'DRANK', 'SLEPT', 'FEVER', 'PIERCING', 'AGE_WEIGHT');
--

--changeset ite4120:blood-04-readiness-questions
--comment The readiness questions from the Estonian donor criteria
/* Real content, so no demo context. Sources, checked 17.10.2026:
   - Sotsiaalministri maarus nr 65, Isiku doonoriks sobivuse kriteeriumid,
     hindamise tingimused ja kord (RT I, 22.11.2023, 3; in force 25.11.2023),
     cited as paragraphs below;
   - the Estonian Blood Centre's eligibility and preparation guidance,
     verekeskus.ee.
   Tattoo, piercing and procedures: the regulation says 6 months, or 4 with a
   negative NAT test; the Blood Centre's public figure of 4 months is used.
   Sexual behaviour, HIV, hepatitis and drug use are deliberately NOT asked:
   the centre covers them in its confidential interview (paragraph 12), and
   asking here would collect more than necessary (BLOOD.01, privacy). */
insert into blood.readiness_question
    (question_code, category, question_text, concern_answer, severity, advice, display_order)
values
    ('ATE', 'PREPARATION',
     'Have you eaten a light meal in the last 2–3 hours?', 'NO', 'ADVISORY',
     'Eat a light, low-fat meal 2–3 hours before donating. From the day before, avoid fatty foods such as fatty pork, cream, mayonnaise and whole milk.', 10),
    ('DRANK', 'PREPARATION',
     'Have you drunk plenty of water or juice today?', 'NO', 'ADVISORY',
     'Drink plenty of water or juice before you go.', 20),
    ('RESTED', 'PREPARATION',
     'Are you well rested?', 'NO', 'ADVISORY',
     'Donate on a day when you are rested.', 30),
    ('PHOTO_ID', 'PREPARATION',
     'Will you bring a photo ID?', 'NO', 'ADVISORY',
     'Bring a photo ID. The centre needs it to register you.', 40),
    ('CHRONIC', 'PREPARATION',
     'Do you have a long-term illness (for example heart disease, diabetes, a bleeding disorder or epilepsy), or have you ever had cancer?', 'YES', 'ADVISORY',
     'Some long-term illnesses rule out donating. Call the blood centre before you go.', 50),
    ('AGE', 'ELIGIBILITY',
     'Are you 18–65 years old (18–60 if this is your first donation)?', 'NO', 'BLOCKING',
     'Donors must be 18–65, and first-time donors 18–60.', 110),
    ('WEIGHT', 'ELIGIBILITY',
     'Do you weigh at least 50 kg?', 'NO', 'BLOCKING',
     'Donors must weigh at least 50 kg.', 120),
    ('RESIDENCE', 'ELIGIBILITY',
     'Are you an Estonian citizen, or have you lived in Estonia with a residence permit or right of residence for at least the last 3 months?', 'NO', 'BLOCKING',
     'You can donate once you have lived in Estonia for 3 months.', 130),
    ('WELL_TODAY', 'ELIGIBILITY',
     'Do you feel healthy today?', 'NO', 'BLOCKING',
     'Don''t donate while you are ill.', 140),
    ('FEVER', 'ELIGIBILITY',
     'Did a fever or flu-like illness end less than 2 weeks ago?', 'YES', 'BLOCKING',
     'Wait 2 weeks after the symptoms are gone.', 150),
    ('ANTIBIOTICS', 'ELIGIBILITY',
     'Have you taken antibiotics in the last 2 weeks?', 'YES', 'BLOCKING',
     'Wait 2 weeks after finishing the course.', 160),
    ('ALCOHOL', 'ELIGIBILITY',
     'Have you drunk alcohol yesterday or today?', 'YES', 'BLOCKING',
     'Don''t drink the day before or on the day of donating. Choose another day.', 170),
    ('RECENT_DONATION', 'ELIGIBILITY',
     'Have you given blood in the last 2 months?', 'YES', 'BLOCKING',
     'Leave at least 2 months between donations (women up to 4 times a year, men up to 6).', 180),
    ('TATTOO', 'ELIGIBILITY',
     'In the last 4 months, have you had a tattoo, piercing or acupuncture?', 'YES', 'BLOCKING',
     'Wait 4 months after it.', 190),
    ('PROCEDURE', 'ELIGIBILITY',
     'In the last 4 months, have you had an endoscopy, a major operation or a blood transfusion?', 'YES', 'BLOCKING',
     'Wait 4 months after it.', 200),
    ('DENTAL', 'ELIGIBILITY',
     'Have you had dental treatment today?', 'YES', 'BLOCKING',
     'You can donate from tomorrow.', 210),
    ('TICK', 'ELIGIBILITY',
     'Have you been bitten by a tick in the last 2 months?', 'YES', 'BLOCKING',
     'Wait 2 months after the bite, if you are well.', 220),
    ('VACCINE', 'ELIGIBILITY',
     'In the last 4 weeks, have you had a live vaccine (such as MMR, chickenpox or yellow fever), or a hepatitis B vaccine in the last 2 weeks?', 'YES', 'BLOCKING',
     'Wait 4 weeks after a live vaccine, or 2 weeks after hepatitis B. Most other vaccines don''t delay donating if you are well.', 230),
    ('MALARIA', 'ELIGIBILITY',
     'Have you come back from a malaria area in the last 12 months?', 'YES', 'BLOCKING',
     'Wait 12 months after leaving the area.', 240),
    ('PREGNANCY', 'ELIGIBILITY',
     'Are you pregnant or breastfeeding, or have you given birth or had a miscarriage in the last 6 months?', 'YES', 'BLOCKING',
     'Wait until 6 months after the birth, and until you stop breastfeeding.', 250);
--
