WITH GAMELIST AS
(
SELECT
    hteamdate,
    substring(hteamdate,8,2) + '/' + substring(hteamdate,10,2) as dte,
    VISITORS,
    left(hteamdate,3) as Home,
    sum(CASE WHEN half =0 and AB=1 THEN 1 ELSE 0 END) As VisAb,
     sum(CASE WHEN half =0 and hitvalue>0 THEN 1 ELSE 0 END) As VisHits,
     sum(CASE WHEN half=0 and hitvalue=4 THEN 1 ELSE 0 END) as VisHRs,
    sum(CASE WHEN half =1 and AB=1 THEN 1 ELSE 0 END) As HomeAb,
    sum(CASE WHEN half =1 and hitvalue>0 THEN 1 ELSE 0 END) As HomeHits,
    sum(CASE WHEN half=1 and hitvalue=4 THEN 1 ELSE 0 END) as HomeHRs,
    sum(CASE WHEN half=0 and CHARINDEX('SB', Result) > 0 THEN 1 ELSE 0 END) as VisSB,
    sum(CASE WHEN half=0 and CHARINDEX('CS', Result) > 0 THEN 1 ELSE 0 END) as VisCS,
    sum(CASE WHEN half=1 and CHARINDEX('SB', Result) > 0 THEN 1 ELSE 0 END) as HmSB,
    sum(CASE WHEN half=1 and CHARINDEX('CS', Result) > 0 THEN 1 ELSE 0 END) as HmCS,
    SUM(CASE 
        WHEN (on2nd IS NOT NULL OR on3rd IS NOT NULL) 
        AND AB = 1 
        AND HALF = 0 
        THEN 1 ELSE 0 END) AS VisRISPAB,
    SUM(CASE 
        WHEN (on2nd IS NOT NULL OR on3rd IS NOT NULL) 
        AND hitvalue>0 
        AND HALF = 0 
        THEN 1 ELSE 0 END) AS VisRISPHits,
     SUM(CASE 
        WHEN (on2nd IS NOT NULL OR on3rd IS NOT NULL) 
        AND AB = 1 
        AND HALF = 1 
        THEN 1 ELSE 0 END) AS HmRISPAB,
     SUM(CASE 
        WHEN (on2nd IS NOT NULL OR on3rd IS NOT NULL) 
        AND hitvalue>0 
        AND HALF = 1
        THEN 1 ELSE 0 END) AS HmRISPHits
FROM
    tblEventLog2025
GROUP BY hteamdate,Visitors
--ORDER BY dte,Home
),
--Getting the runs scored by each team
RunScored AS
(
    SELECT 
        hteamdate,
        --batter,half,
        -- Flag: did the batter score?
        SUM(CASE WHEN HALF=0 AND CAST(batdest AS INT) > 3 
             THEN 1 ELSE 0 END)                 AS visbatterscored,
        SUM(CASE WHEN HALF=1 AND CAST(batdest AS INT) > 3 
             THEN 1 ELSE 0 END)                 AS homebatterscored,
        -- Flag: did the runner on 1st score?
        SUM(CASE WHEN HALF = 0 
              AND on1st IS NOT NULL 
              AND CAST(on1_dest AS INT) > 3 
         THEN 1 ELSE 0 END) AS vison1stscored,
         SUM(CASE WHEN HALF = 1 
              AND on1st IS NOT NULL 
              AND CAST(on1_dest AS INT) > 3 
         THEN 1 ELSE 0 END) AS hmon1stscored,
         SUM(CASE WHEN HALF = 0 
              AND on2nd IS NOT NULL 
              AND CAST(on2_dest AS INT) > 3 
         THEN 1 ELSE 0 END) AS vison2ndscored,
         SUM(CASE WHEN HALF = 1
              AND on2nd IS NOT NULL 
              AND CAST(on2_dest AS INT) > 3 
         THEN 1 ELSE 0 END) AS hmon2ndscored,
         SUM(CASE WHEN HALF = 0 
              AND on3rd IS NOT NULL 
              AND CAST(on3_dest AS INT) > 3 
         THEN 1 ELSE 0 END) AS vison3rdscored,
         SUM(CASE WHEN HALF = 1
              AND on3rd IS NOT NULL 
              AND CAST(on3_dest AS INT) > 3 
         THEN 1 ELSE 0 END) AS hmon3rdscored
    FROM tblEventLog2025
    GROUP BY hteamdate
),
GameStats As
(
SELECT 
    G.*, 
    R.visbatterscored+ R.vison1stscored+ R.vison2ndscored+R.vison3rdscored As Vis_Score,
    R.homebatterscored+R.hmon1stscored+R.hmon2ndscored+R.hmon3rdscored As Hm_Score,
    CASE 
        WHEN
            R.visbatterscored+ R.vison1stscored+ R.vison2ndscored+R.vison3rdscored>
            R.homebatterscored+R.hmon1stscored+R.hmon2ndscored+R.hmon3rdscored
        THEN VISITORS ELSE HOME END as Winner    
FROM GAMELIST G
JOIN RunScored R ON G.hteamdate = R.hteamdate
)
--SELECT * from GameStats
--ORDER BY dte
SELECT 
    hteamdate,
    dte,
    Visitors       AS team,
    'VIS'          AS role,
    VisAb          AS AB,
    VisHits        AS Hits,
    VisHRs         AS HRs,
    VisSB          AS SBs,
    VisCS          AS CS,
    VisRISPAB      AS RISP_AB,
    VisRISPHits    AS RISP_Hits,
    Vis_Score      AS Runs,
    ROUND(CAST(VisRISPHits AS FLOAT) / NULLIF(VisRISPAB, 0), 3) AS RISP_AVG
FROM GameStats

UNION ALL

SELECT 
    hteamdate,
    dte,
    Home           AS team,
    'HM'           AS role,
    HomeAb         AS AB,
    HomeHits       AS Hits,
    HomeHRs        AS HRs,
    HmSB           AS SBs,
    HmCS           AS CS,
    HmRISPAB       AS RISP_AB,
    HmRISPHits     AS RISP_Hits,
    Hm_Score       AS Runs,
    ROUND(CAST(HmRISPHits AS FLOAT) / NULLIF(HmRISPAB, 0), 3) AS RISP_AVG
FROM GameStats

ORDER BY dte, hteamdate, role DESC  -- DESC puts VIS before HM alphabetically
