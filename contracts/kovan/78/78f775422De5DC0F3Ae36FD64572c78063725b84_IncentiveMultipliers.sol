// contracts/multipliers.sol
// SPDX-License-Identifier: UNLICENSED
//Please refer to up30.info for information about this token
pragma solidity 0.8.10;

library IncentiveMultipliers{

function getEarnedTokens(int dayDiff, int transactionAmount) public pure returns (int256) {
        int earnedTokens = 0;
        int incentiveMult = 0;
        if(dayDiff < 360){incentiveMult = getYear01(dayDiff);}//end of year 1
        else if(dayDiff < 720){incentiveMult = getYear02(dayDiff);}//end of year 2
else if(dayDiff < 1080){incentiveMult = getYear03(dayDiff);}//end of year 3
else if(dayDiff < 1440){incentiveMult = getYear04(dayDiff);}//end of year 4
else if(dayDiff < 1800){incentiveMult = getYear05(dayDiff);}//end of year 5
else if(dayDiff < 2160){incentiveMult = getYear06(dayDiff);}//end of year 6
else if(dayDiff < 2520){incentiveMult = getYear07(dayDiff);}//end of year 7
else if(dayDiff < 2880){incentiveMult = getYear08(dayDiff);}//end of year 8
else if(dayDiff < 3240){incentiveMult = getYear09(dayDiff);}//end of year 9
else if(dayDiff < 3600){incentiveMult = getYear10(dayDiff);}//end of year 10
else if(dayDiff < 3960){incentiveMult = getYear11(dayDiff);}//end of year 11
else if(dayDiff < 4320){incentiveMult = getYear12(dayDiff);}//end of year 12
else if(dayDiff < 4680){incentiveMult = getYear13(dayDiff);}//end of year 13
else if(dayDiff < 5040){incentiveMult = getYear14(dayDiff);}//end of year 14
else if(dayDiff < 5400){incentiveMult = getYear15(dayDiff);}//end of year 15
else if(dayDiff < 5760){incentiveMult = getYear16(dayDiff);}//end of year 16
else if(dayDiff < 6120){incentiveMult = getYear17(dayDiff);}//end of year 17
else if(dayDiff < 6480){incentiveMult = getYear18(dayDiff);}//end of year 18
else if(dayDiff < 6840){incentiveMult = getYear19(dayDiff);}//end of year 19
else if(dayDiff < 7200){incentiveMult = getYear20(dayDiff);}//end of year 20
else if(dayDiff < 9000){incentiveMult = getYear25(dayDiff);}//end of year 25
else if(dayDiff < 10800){incentiveMult = getYear30(dayDiff);}//end of year 30
else if(dayDiff < 12600){incentiveMult = getYear35(dayDiff);}//end of year 35
else if(dayDiff < 14400){incentiveMult = getYear40(dayDiff);}//end of year 40
else if(dayDiff < 16200){incentiveMult = getYear45(dayDiff);}//end of year 45
else if(dayDiff < 18000){incentiveMult = getYear50(dayDiff);}//end of year 50
else if(dayDiff < 19800){incentiveMult = getYear55(dayDiff);}//end of year 55
else {incentiveMult = getYear60(dayDiff);}//end of year 60


        earnedTokens = (incentiveMult) * transactionAmount / 1000000000000000;//10^15. Results top changing at 10^14
        return earnedTokens;
    }
    function getYear01(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 330){incentiveMult = 69677547879950;}
        else if(dayDiff >= 300){incentiveMult = 63692858295720;}
        else if(dayDiff >= 270){incentiveMult = 57885692850590;}
        else if(dayDiff >= 240){incentiveMult = 52251297991610;}
        else if(dayDiff >= 210){incentiveMult = 46785042150840;}
        else if(dayDiff >= 180){incentiveMult = 41482412359480;}
        else if(dayDiff >= 150){incentiveMult = 36339010963610;}
        else if(dayDiff >= 120){incentiveMult = 31350552439110;}
        else if(dayDiff >= 90){incentiveMult = 26512860303560;}
        else if(dayDiff >= 60){incentiveMult = 21821864122970;}
        else if(dayDiff >= 30){incentiveMult = 17273596610750;}
        else if(dayDiff >= 15){incentiveMult = 12864190816860;}
        else if(dayDiff >= 7){incentiveMult = 8532152715490;}
        else if(dayDiff >= 3){incentiveMult = 4249363320640;}
        return incentiveMult;
    }
    function getYear02(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 690){incentiveMult = 157253621474130;}
        else if(dayDiff >= 660){incentiveMult = 148718371438970;}
        else if(dayDiff >= 630){incentiveMult = 140428583141820;}
        else if(dayDiff >= 600){incentiveMult = 132377735343930;}
        else if(dayDiff >= 570){incentiveMult = 124559478077740;}
        else if(dayDiff >= 540){incentiveMult = 116967627890200;}
        else if(dayDiff >= 510){incentiveMult = 109596163209200;}
        else if(dayDiff >= 480){incentiveMult = 102439219831830;}
        else if(dayDiff >= 450){incentiveMult = 95491086533100;}
        else if(dayDiff >= 420){incentiveMult = 88746200793690;}
        else if(dayDiff >= 390){incentiveMult = 82199144645140;}
        else if(dayDiff >= 360){incentiveMult = 75844640630680;}

        return incentiveMult;
    }
    function getYear03(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 1050){incentiveMult = 281452477960120;}
        else if(dayDiff >= 1020){incentiveMult = 269393648413480;}
        else if(dayDiff >= 990){incentiveMult = 257673796935430;}
        else if(dayDiff >= 960){incentiveMult = 246283930422180;}
        else if(dayDiff >= 930){incentiveMult = 235215293885400;}
        else if(dayDiff >= 900){incentiveMult = 224459364201080;}
        else if(dayDiff >= 870){incentiveMult = 214007843978340;}
        else if(dayDiff >= 840){incentiveMult = 203852655549950;}
        else if(dayDiff >= 810){incentiveMult = 193985935086260;}
        else if(dayDiff >= 780){incentiveMult = 184400026833710;}
        else if(dayDiff >= 750){incentiveMult = 175087477478780;}
        else if(dayDiff >= 720){incentiveMult = 166041030637980;}

        return incentiveMult;
    }
    function getYear04(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 1410){incentiveMult = 456225931795930;}
else if(dayDiff >= 1380){incentiveMult = 439302211417230;}
else if(dayDiff >= 1350){incentiveMult = 422846384226020;}
else if(dayDiff >= 1320){incentiveMult = 406846073198950;}
else if(dayDiff >= 1290){incentiveMult = 391289222434380;}
else if(dayDiff >= 1260){incentiveMult = 376164089793680;}
else if(dayDiff >= 1230){incentiveMult = 361459239598340;}
else if(dayDiff >= 1200){incentiveMult = 347163535391960;}
else if(dayDiff >= 1170){incentiveMult = 333266132775230;}
else if(dayDiff >= 1140){incentiveMult = 319756472321220;}
else if(dayDiff >= 1110){incentiveMult = 306624272577780;}
else if(dayDiff >= 1080){incentiveMult = 293859523163160;}

        return incentiveMult;
    }
    function getYear05(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 1770){incentiveMult = 700782297682130;}
else if(dayDiff >= 1740){incentiveMult = 677151412367350;}
else if(dayDiff >= 1710){incentiveMult = 654164696998040;}
else if(dayDiff >= 1680){incentiveMult = 631805342841030;}
else if(dayDiff >= 1650){incentiveMult = 610056950463290;}
else if(dayDiff >= 1620){incentiveMult = 588903522736780;}
else if(dayDiff >= 1590){incentiveMult = 568329457716760;}
else if(dayDiff >= 1560){incentiveMult = 548319541414830;}
else if(dayDiff >= 1530){incentiveMult = 528858940486950;}
else if(dayDiff >= 1500){incentiveMult = 509933194855390;}
else if(dayDiff >= 1470){incentiveMult = 491528210282380;}
else if(dayDiff >= 1440){incentiveMult = 473630250912010;}

        return incentiveMult;
    }
    function getYear06(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 2130){incentiveMult = 1041303452954250;}
else if(dayDiff >= 2100){incentiveMult = 1008473775466380;}
else if(dayDiff >= 2070){incentiveMult = 976524160885260;}
else if(dayDiff >= 2040){incentiveMult = 945432424634820;}
else if(dayDiff >= 2010){incentiveMult = 915176855805160;}
else if(dayDiff >= 1980){incentiveMult = 885736213859630;}
else if(dayDiff >= 1950){incentiveMult = 857089724846810;}
else if(dayDiff >= 1920){incentiveMult = 829217077156550;}
else if(dayDiff >= 1890){incentiveMult = 802098416857500;}
else if(dayDiff >= 1860){incentiveMult = 775714342651830;}
else if(dayDiff >= 1830){incentiveMult = 750045900481890;}
else if(dayDiff >= 1800){incentiveMult = 725074577821340;}

        return incentiveMult;
    }
    function getYear07(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 2490){incentiveMult = 1512633131231160;}
else if(dayDiff >= 2460){incentiveMult = 1467338085482910;}
else if(dayDiff >= 2430){incentiveMult = 1423226597514800;}
else if(dayDiff >= 2400){incentiveMult = 1380270781842650;}
else if(dayDiff >= 2370){incentiveMult = 1338443211341430;}
else if(dayDiff >= 2340){incentiveMult = 1297716923462760;}
else if(dayDiff >= 2310){incentiveMult = 1258065425379810;}
else if(dayDiff >= 2280){incentiveMult = 1219462698114330;}
else if(dayDiff >= 2250){incentiveMult = 1181883199699170;}
else if(dayDiff >= 2220){incentiveMult = 1145301867429160;}
else if(dayDiff >= 2190){incentiveMult = 1109694119251850;}
else if(dayDiff >= 2160){incentiveMult = 1075035854348440;}

        return incentiveMult;
    }
    function getYear08(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 2850){incentiveMult = 2159224961072130;}
else if(dayDiff >= 2820){incentiveMult = 2097399172238510;}
else if(dayDiff >= 2790){incentiveMult = 2037123348501230;}
else if(dayDiff >= 2760){incentiveMult = 1978365055491800;}
else if(dayDiff >= 2730){incentiveMult = 1921092138665360;}
else if(dayDiff >= 2700){incentiveMult = 1865272746715680;}
else if(dayDiff >= 2670){incentiveMult = 1810875353262050;}
else if(dayDiff >= 2640){incentiveMult = 1757868776857900;}
else if(dayDiff >= 2610){incentiveMult = 1706222199372670;}
else if(dayDiff >= 2580){incentiveMult = 1655905182800070;}
else if(dayDiff >= 2550){incentiveMult = 1606887684546950;}
else if(dayDiff >= 2520){incentiveMult = 1559140071257850;}

        return incentiveMult;
    }
    function getYear09(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 3210){incentiveMult = 3034094715520160;}
else if(dayDiff >= 3180){incentiveMult = 2951077653337180;}
else if(dayDiff >= 3150){incentiveMult = 2870010528166110;}
else if(dayDiff >= 3120){incentiveMult = 2790860059171600;}
else if(dayDiff >= 3090){incentiveMult = 2713592815365330;}
else if(dayDiff >= 3060){incentiveMult = 2638175262521620;}
else if(dayDiff >= 3030){incentiveMult = 2564573808034840;}
else if(dayDiff >= 3000){incentiveMult = 2492754843718560;}
else if(dayDiff >= 2970){incentiveMult = 2422684786552940;}
else if(dayDiff >= 2940){incentiveMult = 2354330117392850;}
else if(dayDiff >= 2910){incentiveMult = 2287657417654450;}
else if(dayDiff >= 2880){incentiveMult = 2222633404003390;}

        return incentiveMult;
    }
    function getYear10(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 3570){incentiveMult = 4194073952581150;}
else if(dayDiff >= 3540){incentiveMult = 4085189197976600;}
else if(dayDiff >= 3510){incentiveMult = 3978622241779480;}
else if(dayDiff >= 3480){incentiveMult = 3874345981347660;}
else if(dayDiff >= 3450){incentiveMult = 3772332450632690;}
else if(dayDiff >= 3420){incentiveMult = 3672552888979140;}
else if(dayDiff >= 3390){incentiveMult = 3574977808494030;}
else if(dayDiff >= 3360){incentiveMult = 3479577059882840;}
else if(dayDiff >= 3330){incentiveMult = 3386319896658080;}
else if(dayDiff >= 3300){incentiveMult = 3295175037637130;}
else if(dayDiff >= 3270){incentiveMult = 3206110727655300;}
else if(dayDiff >= 3240){incentiveMult = 3119094796429890;}

        return incentiveMult;
    }
    function getYear11(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 3930){incentiveMult = 5689851968731980;}
else if(dayDiff >= 3900){incentiveMult = 5551452450385520;}
else if(dayDiff >= 3870){incentiveMult = 5415602202896340;}
else if(dayDiff >= 3840){incentiveMult = 5282290184599860;}
else if(dayDiff >= 3810){incentiveMult = 5151503605121790;}
else if(dayDiff >= 3780){incentiveMult = 5023227999516990;}
else if(dayDiff >= 3750){incentiveMult = 4897447303011830;}
else if(dayDiff >= 3720){incentiveMult = 4774143926129220;}
else if(dayDiff >= 3690){incentiveMult = 4653298829984050;}
else if(dayDiff >= 3660){incentiveMult = 4534891601544960;}
else if(dayDiff >= 3630){incentiveMult = 4418900528667590;}
else if(dayDiff >= 3600){incentiveMult = 4305302674713820;}

        return incentiveMult;
    }
    function getYear12(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 4290){incentiveMult = 7550812636354470;}
else if(dayDiff >= 4260){incentiveMult = 7381692777755980;}
else if(dayDiff >= 4230){incentiveMult = 7215093168798830;}
else if(dayDiff >= 4200){incentiveMult = 7051028987990010;}
else if(dayDiff >= 4170){incentiveMult = 6889512910660660;}
else if(dayDiff >= 4140){incentiveMult = 6730555156741700;}
else if(dayDiff >= 4110){incentiveMult = 6574163542135410;}
else if(dayDiff >= 4080){incentiveMult = 6420343533430520;}
else if(dayDiff >= 4050){incentiveMult = 6269098305705290;}
else if(dayDiff >= 4020){incentiveMult = 6120428803160970;}
else if(dayDiff >= 3990){incentiveMult = 5974333802327450;}
else if(dayDiff >= 3960){incentiveMult = 5830809977583050;}

        return incentiveMult;
    }
    function getYear13(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 4650){incentiveMult = 9767731998251200;}
else if(dayDiff >= 4620){incentiveMult = 9570510803605700;}
else if(dayDiff >= 4590){incentiveMult = 9375421009660500;}
else if(dayDiff >= 4560){incentiveMult = 9182509935687500;}
else if(dayDiff >= 4530){incentiveMult = 8991822186944450;}
else if(dayDiff >= 4500){incentiveMult = 8803399642503160;}
else if(dayDiff >= 4470){incentiveMult = 8617281448991690;}
else if(dayDiff >= 4440){incentiveMult = 8433504020136980;}
else if(dayDiff >= 4410){incentiveMult = 8252101041972510;}
else if(dayDiff >= 4380){incentiveMult = 8073103483560740;}
else if(dayDiff >= 4350){incentiveMult = 7896539613063540;}
else if(dayDiff >= 4320){incentiveMult = 7722435018979630;}

        return incentiveMult;
    }
    function getYear14(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 5010){incentiveMult = 12279835322143300;}
else if(dayDiff >= 4980){incentiveMult = 12061672866141500;}
else if(dayDiff >= 4950){incentiveMult = 11844875050760200;}
else if(dayDiff >= 4920){incentiveMult = 11629518590678700;}
else if(dayDiff >= 4890){incentiveMult = 11415678108355700;}
else if(dayDiff >= 4860){incentiveMult = 11203426049382600;}
else if(dayDiff >= 4830){incentiveMult = 10992832603487900;}
else if(dayDiff >= 4800){incentiveMult = 10783965631341000;}
else if(dayDiff >= 4770){incentiveMult = 10576890597278200;}
else if(dayDiff >= 4740){incentiveMult = 10371670508053600;}
else if(dayDiff >= 4710){incentiveMult = 10168365857691900;}
else if(dayDiff >= 4680){incentiveMult = 9967034578497300;}

        return incentiveMult;
    }
    function getYear15(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 5370){incentiveMult = 14973880078907600;}
else if(dayDiff >= 5340){incentiveMult = 14745949535210600;}
else if(dayDiff >= 5310){incentiveMult = 14518337477715100;}
else if(dayDiff >= 5280){incentiveMult = 14291137362710000;}
else if(dayDiff >= 5250){incentiveMult = 14064441928415100;}
else if(dayDiff >= 5220){incentiveMult = 13838343061514300;}
else if(dayDiff >= 5190){incentiveMult = 13612931666030600;}
else if(dayDiff >= 5160){incentiveMult = 13388297534905800;}
else if(dayDiff >= 5130){incentiveMult = 13164529224633800;}
else if(dayDiff >= 5100){incentiveMult = 12941713933285800;}
else if(dayDiff >= 5070){incentiveMult = 12719937382250100;}
else if(dayDiff >= 5040){incentiveMult = 12499283701994400;}

        return incentiveMult;
    }
    function getYear16(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 5730){incentiveMult = 17699490198600400;}
else if(dayDiff >= 5700){incentiveMult = 17475101069709700;}
else if(dayDiff >= 5670){incentiveMult = 17249903060068400;}
else if(dayDiff >= 5640){incentiveMult = 17023987500451400;}
else if(dayDiff >= 5610){incentiveMult = 16797446648583800;}
else if(dayDiff >= 5580){incentiveMult = 16570373557484200;}
else if(dayDiff >= 5550){incentiveMult = 16342861941565000;}
else if(dayDiff >= 5520){incentiveMult = 16115006040849100;}
else if(dayDiff >= 5490){incentiveMult = 15886900483677700;}
else if(dayDiff >= 5460){incentiveMult = 15658640148286800;}
else if(dayDiff >= 5430){incentiveMult = 15430320023636900;}
else if(dayDiff >= 5400){incentiveMult = 15202035069887800;}

        return incentiveMult;
    }
    function getYear17(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 6090){incentiveMult = 20297624618414700;}
else if(dayDiff >= 6060){incentiveMult = 20089562632206300;}
else if(dayDiff >= 6030){incentiveMult = 19879711531040100;}
else if(dayDiff >= 6000){incentiveMult = 19668142508001200;}
else if(dayDiff >= 5970){incentiveMult = 19454928974359900;}
else if(dayDiff >= 5940){incentiveMult = 19240146477995100;}
else if(dayDiff >= 5910){incentiveMult = 19023872616398100;}
else if(dayDiff >= 5880){incentiveMult = 18806186944418600;}
else if(dayDiff >= 5850){incentiveMult = 18587170876933200;}
else if(dayDiff >= 5820){incentiveMult = 18366907586640000;}
else if(dayDiff >= 5790){incentiveMult = 18145481897201100;}
else if(dayDiff >= 5760){incentiveMult = 17922980171975000;}

        return incentiveMult;
    }
    function getYear18(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 6450){incentiveMult = 22632216799620900;}
else if(dayDiff >= 6420){incentiveMult = 22450283456695000;}
else if(dayDiff >= 6390){incentiveMult = 22265901561110800;}
else if(dayDiff >= 6360){incentiveMult = 22079111422949300;}
else if(dayDiff >= 6330){incentiveMult = 21889956097411100;}
else if(dayDiff >= 6300){incentiveMult = 21698481373059200;}
else if(dayDiff >= 6270){incentiveMult = 21504735754354400;}
else if(dayDiff >= 6240){incentiveMult = 21308770438400000;}
else if(dayDiff >= 6210){incentiveMult = 21110639285829000;}
else if(dayDiff >= 6180){incentiveMult = 20910398785786900;}
else if(dayDiff >= 6150){incentiveMult = 20708108014980600;}
else if(dayDiff >= 6120){incentiveMult = 20503828590784300;}

        return incentiveMult;
    }
    function getYear19(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 6810){incentiveMult = 24613488595468900;}
else if(dayDiff >= 6780){incentiveMult = 24463090198917200;}
else if(dayDiff >= 6750){incentiveMult = 24309970692161300;}
else if(dayDiff >= 6720){incentiveMult = 24154138424345500;}
else if(dayDiff >= 6690){incentiveMult = 23995604236117100;}
else if(dayDiff >= 6660){incentiveMult = 23834381504701400;}
else if(dayDiff >= 6630){incentiveMult = 23670486185298000;}
else if(dayDiff >= 6600){incentiveMult = 23503936848581000;}
else if(dayDiff >= 6570){incentiveMult = 23334754714089000;}
else if(dayDiff >= 6540){incentiveMult = 23162963679299000;}
else if(dayDiff >= 6510){incentiveMult = 22988590344186300;}
else if(dayDiff >= 6480){incentiveMult = 22811664031077800;}

        return incentiveMult;
    }
    function getYear20(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 7170){incentiveMult = 26206149336829100;}
else if(dayDiff >= 7140){incentiveMult = 26088223389557100;}
else if(dayDiff >= 7110){incentiveMult = 25967650038435500;}
else if(dayDiff >= 7080){incentiveMult = 25844412280564300;}
else if(dayDiff >= 7050){incentiveMult = 25718494859115500;}
else if(dayDiff >= 7020){incentiveMult = 25589884334922200;}
else if(dayDiff >= 6990){incentiveMult = 25458569157074600;}
else if(dayDiff >= 6960){incentiveMult = 25324539732312600;}
else if(dayDiff >= 6930){incentiveMult = 25187788493001100;}
else if(dayDiff >= 6900){incentiveMult = 25048309963468000;}
else if(dayDiff >= 6870){incentiveMult = 24906100824481800;}
else if(dayDiff >= 6840){incentiveMult = 24761159975644200;}

        return incentiveMult;
    }

    function getYear25(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 8970){incentiveMult = 29609537096114900;}
else if(dayDiff >= 8940){incentiveMult = 29591719488553900;}
else if(dayDiff >= 8910){incentiveMult = 29573182955573300;}
else if(dayDiff >= 8880){incentiveMult = 29553903303655300;}
else if(dayDiff >= 8850){incentiveMult = 29533855765060100;}
else if(dayDiff >= 8820){incentiveMult = 29513014996327000;}
else if(dayDiff >= 8790){incentiveMult = 29491355077517400;}
else if(dayDiff >= 8760){incentiveMult = 29468849512245500;}
else if(dayDiff >= 8730){incentiveMult = 29445471228538000;}
else if(dayDiff >= 8700){incentiveMult = 29421192580568300;}
else if(dayDiff >= 8670){incentiveMult = 29395985351310500;}
else if(dayDiff >= 8640){incentiveMult = 29369820756157900;}
else if(dayDiff >= 8610){incentiveMult = 29342669447553300;}
else if(dayDiff >= 8580){incentiveMult = 29314501520676800;}
else if(dayDiff >= 8550){incentiveMult = 29285286520238900;}
else if(dayDiff >= 8520){incentiveMult = 29254993448425900;}
else if(dayDiff >= 8490){incentiveMult = 29223590774043300;}
else if(dayDiff >= 8460){incentiveMult = 29191046442907600;}
else if(dayDiff >= 8430){incentiveMult = 29157327889530000;}
else if(dayDiff >= 8400){incentiveMult = 29122402050141000;}
else if(dayDiff >= 8370){incentiveMult = 29086235377101200;}
else if(dayDiff >= 8340){incentiveMult = 29048793854743800;}
else if(dayDiff >= 8310){incentiveMult = 29010043016693500;}
else if(dayDiff >= 8280){incentiveMult = 28969947964705200;}
else if(dayDiff >= 8250){incentiveMult = 28928473389064900;}
else if(dayDiff >= 8220){incentiveMult = 28885583590594200;}
else if(dayDiff >= 8190){incentiveMult = 28841242504296500;}
else if(dayDiff >= 8160){incentiveMult = 28795413724682900;}
else if(dayDiff >= 8130){incentiveMult = 28748060532812800;}
else if(dayDiff >= 8100){incentiveMult = 28699145925082100;}
else if(dayDiff >= 8070){incentiveMult = 28648632643788300;}
else if(dayDiff >= 8040){incentiveMult = 28596483209501100;}
else if(dayDiff >= 8010){incentiveMult = 28542659955260600;}
else if(dayDiff >= 7980){incentiveMult = 28487125062625700;}
else if(dayDiff >= 7950){incentiveMult = 28429840599587800;}
else if(dayDiff >= 7920){incentiveMult = 28370768560363600;}
else if(dayDiff >= 7890){incentiveMult = 28309870907075200;}
else if(dayDiff >= 7860){incentiveMult = 28247109613321000;}
else if(dayDiff >= 7830){incentiveMult = 28182446709637400;}
else if(dayDiff >= 7800){incentiveMult = 28115844330843600;}
else if(dayDiff >= 7770){incentiveMult = 28047264765259800;}
else if(dayDiff >= 7740){incentiveMult = 27976670505779300;}
else if(dayDiff >= 7710){incentiveMult = 27904024302772600;}
else if(dayDiff >= 7680){incentiveMult = 27829289218793300;}
else if(dayDiff >= 7650){incentiveMult = 27752428685048900;}
else if(dayDiff >= 7620){incentiveMult = 27673406559594200;}
else if(dayDiff >= 7590){incentiveMult = 27592187187196400;}
else if(dayDiff >= 7560){incentiveMult = 27508735460814500;}
else if(dayDiff >= 7530){incentiveMult = 27423016884627900;}
else if(dayDiff >= 7500){incentiveMult = 27334997638542000;}
else if(dayDiff >= 7470){incentiveMult = 27244644644088300;}
else if(dayDiff >= 7440){incentiveMult = 27151925631632800;}
else if(dayDiff >= 7410){incentiveMult = 27056809208793300;}
else if(dayDiff >= 7380){incentiveMult = 26959264929962400;}
else if(dayDiff >= 7350){incentiveMult = 26859263366821200;}
else if(dayDiff >= 7320){incentiveMult = 26756776179722700;}
else if(dayDiff >= 7290){incentiveMult = 26651776189814900;}
else if(dayDiff >= 7260){incentiveMult = 26544237451763500;}
else if(dayDiff >= 7230){incentiveMult = 26434135326929700;}
else if(dayDiff >= 7200){incentiveMult = 26321446556846100;}

        return incentiveMult;
    }
    function getYear30(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 10770){incentiveMult = 29982177350370000;}
else if(dayDiff >= 10740){incentiveMult = 29981103409175300;}
else if(dayDiff >= 10710){incentiveMult = 29979970304725800;}
else if(dayDiff >= 10680){incentiveMult = 29978775049089700;}
else if(dayDiff >= 10650){incentiveMult = 29977514519561600;}
else if(dayDiff >= 10620){incentiveMult = 29976185453497900;}
else if(dayDiff >= 10590){incentiveMult = 29974784443003100;}
else if(dayDiff >= 10560){incentiveMult = 29973307929468500;}
else if(dayDiff >= 10530){incentiveMult = 29971752197958500;}
else if(dayDiff >= 10500){incentiveMult = 29970113371446100;}
else if(dayDiff >= 10470){incentiveMult = 29968387404895300;}
else if(dayDiff >= 10440){incentiveMult = 29966570079189900;}
else if(dayDiff >= 10410){incentiveMult = 29964656994907900;}
else if(dayDiff >= 10380){incentiveMult = 29962643565942800;}
else if(dayDiff >= 10350){incentiveMult = 29960525012968900;}
else if(dayDiff >= 10320){incentiveMult = 29958296356753600;}
else if(dayDiff >= 10290){incentiveMult = 29955952411316200;}
else if(dayDiff >= 10260){incentiveMult = 29953487776932900;}
else if(dayDiff >= 10230){incentiveMult = 29950896832991800;}
else if(dayDiff >= 10200){incentiveMult = 29948173730696500;}
else if(dayDiff >= 10170){incentiveMult = 29945312385622600;}
else if(dayDiff >= 10140){incentiveMult = 29942306470128000;}
else if(dayDiff >= 10110){incentiveMult = 29939149405619500;}
else if(dayDiff >= 10080){incentiveMult = 29935834354680800;}
else if(dayDiff >= 10050){incentiveMult = 29932354213062600;}
else if(dayDiff >= 10020){incentiveMult = 29928701601541400;}
else if(dayDiff >= 9990){incentiveMult = 29924868857650000;}
else if(dayDiff >= 9960){incentiveMult = 29920848027285500;}
else if(dayDiff >= 9930){incentiveMult = 29916630856200100;}
else if(dayDiff >= 9900){incentiveMult = 29912208781381800;}
else if(dayDiff >= 9870){incentiveMult = 29907572922329800;}
else if(dayDiff >= 9840){incentiveMult = 29902714072235000;}
else if(dayDiff >= 9810){incentiveMult = 29897622689070900;}
else if(dayDiff >= 9780){incentiveMult = 29892288886605500;}
else if(dayDiff >= 9750){incentiveMult = 29886702425342900;}
else if(dayDiff >= 9720){incentiveMult = 29880852703405600;}
else if(dayDiff >= 9690){incentiveMult = 29874728747367100;}
else if(dayDiff >= 9660){incentiveMult = 29868319203048600;}
else if(dayDiff >= 9630){incentiveMult = 29861612326290300;}
else if(dayDiff >= 9600){incentiveMult = 29854595973712900;}
else if(dayDiff >= 9570){incentiveMult = 29847257593481600;}
else if(dayDiff >= 9540){incentiveMult = 29839584216089300;}
else if(dayDiff >= 9510){incentiveMult = 29831562445174700;}
else if(dayDiff >= 9480){incentiveMult = 29823178448392300;}
else if(dayDiff >= 9450){incentiveMult = 29814417948352800;}
else if(dayDiff >= 9420){incentiveMult = 29805266213651700;}
else if(dayDiff >= 9390){incentiveMult = 29795708050008800;}
else if(dayDiff >= 9360){incentiveMult = 29785727791536700;}
else if(dayDiff >= 9330){incentiveMult = 29775309292162700;}
else if(dayDiff >= 9300){incentiveMult = 29764435917226900;}
else if(dayDiff >= 9270){incentiveMult = 29753090535279800;}
else if(dayDiff >= 9240){incentiveMult = 29741255510106800;}
else if(dayDiff >= 9210){incentiveMult = 29728912693004400;}
else if(dayDiff >= 9180){incentiveMult = 29716043415337200;}
else if(dayDiff >= 9150){incentiveMult = 29702628481404000;}
else if(dayDiff >= 9120){incentiveMult = 29688648161642900;}
else if(dayDiff >= 9090){incentiveMult = 29674082186207200;}
else if(dayDiff >= 9060){incentiveMult = 29658909738944200;}
else if(dayDiff >= 9030){incentiveMult = 29643109451809600;}
else if(dayDiff >= 9000){incentiveMult = 29626659399753900;}

        return incentiveMult;
    }
    function getYear35(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 12570){incentiveMult = 29999946125998200;}
else if(dayDiff >= 12540){incentiveMult = 29999917674591100;}
else if(dayDiff >= 12510){incentiveMult = 29999887246715900;}
else if(dayDiff >= 12480){incentiveMult = 29999854712394100;}
else if(dayDiff >= 12450){incentiveMult = 29999819933630300;}
else if(dayDiff >= 12420){incentiveMult = 29999782763954400;}
else if(dayDiff >= 12390){incentiveMult = 29999743047940300;}
else if(dayDiff >= 12360){incentiveMult = 29999700620700000;}
else if(dayDiff >= 12330){incentiveMult = 29999655307351600;}
else if(dayDiff >= 12300){incentiveMult = 29999606922460700;}
else if(dayDiff >= 12270){incentiveMult = 29999555269453000;}
else if(dayDiff >= 12240){incentiveMult = 29999500139997900;}
else if(dayDiff >= 12210){incentiveMult = 29999441313361600;}
else if(dayDiff >= 12180){incentiveMult = 29999378555727700;}
else if(dayDiff >= 12150){incentiveMult = 29999311619484800;}
else if(dayDiff >= 12120){incentiveMult = 29999240242479400;}
else if(dayDiff >= 12090){incentiveMult = 29999164147232100;}
else if(dayDiff >= 12060){incentiveMult = 29999083040116700;}
else if(dayDiff >= 12030){incentiveMult = 29998996610499800;}
else if(dayDiff >= 12000){incentiveMult = 29998904529839500;}
else if(dayDiff >= 11970){incentiveMult = 29998806450741900;}
else if(dayDiff >= 11940){incentiveMult = 29998702005973300;}
else if(dayDiff >= 11910){incentiveMult = 29998590807426400;}
else if(dayDiff >= 11880){incentiveMult = 29998472445039200;}
else if(dayDiff >= 11850){incentiveMult = 29998346485664500;}
else if(dayDiff >= 11820){incentiveMult = 29998212471887300;}
else if(dayDiff >= 11790){incentiveMult = 29998069920790300;}
else if(dayDiff >= 11760){incentiveMult = 29997918322663000;}
else if(dayDiff >= 11730){incentiveMult = 29997757139654200;}
else if(dayDiff >= 11700){incentiveMult = 29997585804364900;}
else if(dayDiff >= 11670){incentiveMult = 29997403718380200;}
else if(dayDiff >= 11640){incentiveMult = 29997210250737500;}
else if(dayDiff >= 11610){incentiveMult = 29997004736328700;}
else if(dayDiff >= 11580){incentiveMult = 29996786474234900;}
else if(dayDiff >= 11550){incentiveMult = 29996554725990500;}
else if(dayDiff >= 11520){incentiveMult = 29996308713774700;}
else if(dayDiff >= 11490){incentiveMult = 29996047618528400;}
else if(dayDiff >= 11460){incentiveMult = 29995770577993400;}
else if(dayDiff >= 11430){incentiveMult = 29995476684672000;}
else if(dayDiff >= 11400){incentiveMult = 29995164983703900;}
else if(dayDiff >= 11370){incentiveMult = 29994834470658700;}
else if(dayDiff >= 11340){incentiveMult = 29994484089241400;}
else if(dayDiff >= 11310){incentiveMult = 29994112728906900;}
else if(dayDiff >= 11280){incentiveMult = 29993719222383000;}
else if(dayDiff >= 11250){incentiveMult = 29993302343097600;}
else if(dayDiff >= 11220){incentiveMult = 29992860802508600;}
else if(dayDiff >= 11190){incentiveMult = 29992393247333200;}
else if(dayDiff >= 11160){incentiveMult = 29991898256673700;}
else if(dayDiff >= 11130){incentiveMult = 29991374339038400;}
else if(dayDiff >= 11100){incentiveMult = 29990819929253100;}
else if(dayDiff >= 11070){incentiveMult = 29990233385261900;}
else if(dayDiff >= 11040){incentiveMult = 29989612984814700;}
else if(dayDiff >= 11010){incentiveMult = 29988956922037400;}
else if(dayDiff >= 10980){incentiveMult = 29988263303883500;}
else if(dayDiff >= 10950){incentiveMult = 29987530146464300;}
else if(dayDiff >= 10920){incentiveMult = 29986755371254100;}
else if(dayDiff >= 10890){incentiveMult = 29985936801169600;}
else if(dayDiff >= 10860){incentiveMult = 29985072156519000;}
else if(dayDiff >= 10830){incentiveMult = 29984159050820600;}
else if(dayDiff >= 10800){incentiveMult = 29983194986486400;}

        return incentiveMult;
    }
    function getYear40(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 14370){incentiveMult = 30000332644298000;}
else if(dayDiff >= 14340){incentiveMult = 30000332309185500;}
else if(dayDiff >= 14310){incentiveMult = 30000331945921900;}
else if(dayDiff >= 14280){incentiveMult = 30000331552230900;}
else if(dayDiff >= 14250){incentiveMult = 30000331125660000;}
else if(dayDiff >= 14220){incentiveMult = 30000330663566900;}
else if(dayDiff >= 14190){incentiveMult = 30000330163106400;}
else if(dayDiff >= 14160){incentiveMult = 30000329621214700;}
else if(dayDiff >= 14130){incentiveMult = 30000329034593900;}
else if(dayDiff >= 14100){incentiveMult = 30000328399694700;}
else if(dayDiff >= 14070){incentiveMult = 30000327712698600;}
else if(dayDiff >= 14040){incentiveMult = 30000326969498000;}
else if(dayDiff >= 14010){incentiveMult = 30000326165675400;}
else if(dayDiff >= 13980){incentiveMult = 30000325296481600;}
else if(dayDiff >= 13950){incentiveMult = 30000324356811900;}
else if(dayDiff >= 13920){incentiveMult = 30000323341180200;}
else if(dayDiff >= 13890){incentiveMult = 30000322243693100;}
else if(dayDiff >= 13860){incentiveMult = 30000321058020000;}
else if(dayDiff >= 13830){incentiveMult = 30000319777363200;}
else if(dayDiff >= 13800){incentiveMult = 30000318394424700;}
else if(dayDiff >= 13770){incentiveMult = 30000316901371700;}
else if(dayDiff >= 13740){incentiveMult = 30000315289799200;}
else if(dayDiff >= 13710){incentiveMult = 30000313550690200;}
else if(dayDiff >= 13680){incentiveMult = 30000311674374100;}
else if(dayDiff >= 13650){incentiveMult = 30000309650481400;}
else if(dayDiff >= 13620){incentiveMult = 30000307467895900;}
else if(dayDiff >= 13590){incentiveMult = 30000305114704100;}
else if(dayDiff >= 13560){incentiveMult = 30000302578141000;}
else if(dayDiff >= 13530){incentiveMult = 30000299844532800;}
else if(dayDiff >= 13500){incentiveMult = 30000296899235200;}
else if(dayDiff >= 13470){incentiveMult = 30000293726569200;}
else if(dayDiff >= 13440){incentiveMult = 30000290309751400;}
else if(dayDiff >= 13410){incentiveMult = 30000286630821200;}
else if(dayDiff >= 13380){incentiveMult = 30000282670562300;}
else if(dayDiff >= 13350){incentiveMult = 30000278408420700;}
else if(dayDiff >= 13320){incentiveMult = 30000273822416500;}
else if(dayDiff >= 13290){incentiveMult = 30000268889050800;}
else if(dayDiff >= 13260){incentiveMult = 30000263583207200;}
else if(dayDiff >= 13230){incentiveMult = 30000257878046900;}
else if(dayDiff >= 13200){incentiveMult = 30000251744897400;}
else if(dayDiff >= 13170){incentiveMult = 30000245153135500;}
else if(dayDiff >= 13140){incentiveMult = 30000238070061800;}
else if(dayDiff >= 13110){incentiveMult = 30000230460769200;}
else if(dayDiff >= 13080){incentiveMult = 30000222288002900;}
else if(dayDiff >= 13050){incentiveMult = 30000213512012200;}
else if(dayDiff >= 13020){incentiveMult = 30000204090394000;}
else if(dayDiff >= 12990){incentiveMult = 30000193977926900;}
else if(dayDiff >= 12960){incentiveMult = 30000183126395900;}
else if(dayDiff >= 12930){incentiveMult = 30000171484406800;}
else if(dayDiff >= 12900){incentiveMult = 30000158997190800;}
else if(dayDiff >= 12870){incentiveMult = 30000145606396600;}
else if(dayDiff >= 12840){incentiveMult = 30000131249872200;}
else if(dayDiff >= 12810){incentiveMult = 30000115861433200;}
else if(dayDiff >= 12780){incentiveMult = 30000099370619500;}
else if(dayDiff >= 12750){incentiveMult = 30000081702437300;}
else if(dayDiff >= 12720){incentiveMult = 30000062777087200;}
else if(dayDiff >= 12690){incentiveMult = 30000042509677800;}
else if(dayDiff >= 12660){incentiveMult = 30000020809923400;}
else if(dayDiff >= 12630){incentiveMult = 29999997581824700;}
else if(dayDiff >= 12600){incentiveMult = 29999972723333500;}

        return incentiveMult;
    }
    function getYear45(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 16170){incentiveMult = 30000336480048400;}
else if(dayDiff >= 16140){incentiveMult = 30000336478292500;}
else if(dayDiff >= 16110){incentiveMult = 30000336476363200;}
else if(dayDiff >= 16080){incentiveMult = 30000336474244000;}
else if(dayDiff >= 16050){incentiveMult = 30000336471916500;}
else if(dayDiff >= 16020){incentiveMult = 30000336469361000;}
else if(dayDiff >= 15990){incentiveMult = 30000336466555600;}
else if(dayDiff >= 15960){incentiveMult = 30000336463476700;}
else if(dayDiff >= 15930){incentiveMult = 30000336460098400;}
else if(dayDiff >= 15900){incentiveMult = 30000336456392400;}
else if(dayDiff >= 15870){incentiveMult = 30000336452327700;}
else if(dayDiff >= 15840){incentiveMult = 30000336447870800;}
else if(dayDiff >= 15810){incentiveMult = 30000336442984700;}
else if(dayDiff >= 15780){incentiveMult = 30000336437629500;}
else if(dayDiff >= 15750){incentiveMult = 30000336431761500;}
else if(dayDiff >= 15720){incentiveMult = 30000336425332800;}
else if(dayDiff >= 15690){incentiveMult = 30000336418291600;}
else if(dayDiff >= 15660){incentiveMult = 30000336410581200;}
else if(dayDiff >= 15630){incentiveMult = 30000336402140000;}
else if(dayDiff >= 15600){incentiveMult = 30000336392900700;}
else if(dayDiff >= 15570){incentiveMult = 30000336382790100;}
else if(dayDiff >= 15540){incentiveMult = 30000336371728700;}
else if(dayDiff >= 15510){incentiveMult = 30000336359629600;}
else if(dayDiff >= 15480){incentiveMult = 30000336346398600;}
else if(dayDiff >= 15450){incentiveMult = 30000336331932900;}
else if(dayDiff >= 15420){incentiveMult = 30000336316120900;}
else if(dayDiff >= 15390){incentiveMult = 30000336298841300;}
else if(dayDiff >= 15360){incentiveMult = 30000336279962000;}
else if(dayDiff >= 15330){incentiveMult = 30000336259339600;}
else if(dayDiff >= 15300){incentiveMult = 30000336236818100;}
else if(dayDiff >= 15270){incentiveMult = 30000336212228400;}
else if(dayDiff >= 15240){incentiveMult = 30000336185386400;}
else if(dayDiff >= 15210){incentiveMult = 30000336156092600;}
else if(dayDiff >= 15180){incentiveMult = 30000336124130000;}
else if(dayDiff >= 15150){incentiveMult = 30000336089263400;}
else if(dayDiff >= 15120){incentiveMult = 30000336051237500;}
else if(dayDiff >= 15090){incentiveMult = 30000336009775500;}
else if(dayDiff >= 15060){incentiveMult = 30000335964576800;}
else if(dayDiff >= 15030){incentiveMult = 30000335915316000;}
else if(dayDiff >= 15000){incentiveMult = 30000335861640000;}
else if(dayDiff >= 14970){incentiveMult = 30000335803166200;}
else if(dayDiff >= 14940){incentiveMult = 30000335739480100;}
else if(dayDiff >= 14910){incentiveMult = 30000335670132700;}
else if(dayDiff >= 14880){incentiveMult = 30000335594637700;}
else if(dayDiff >= 14850){incentiveMult = 30000335512468600;}
else if(dayDiff >= 14820){incentiveMult = 30000335423055600;}
else if(dayDiff >= 14790){incentiveMult = 30000335325781900;}
else if(dayDiff >= 14760){incentiveMult = 30000335219980200;}
else if(dayDiff >= 14730){incentiveMult = 30000335104928800;}
else if(dayDiff >= 14700){incentiveMult = 30000334979847200;}
else if(dayDiff >= 14670){incentiveMult = 30000334843891600;}
else if(dayDiff >= 14640){incentiveMult = 30000334696149700;}
else if(dayDiff >= 14610){incentiveMult = 30000334535636100;}
else if(dayDiff >= 14580){incentiveMult = 30000334361285800;}
else if(dayDiff >= 14550){incentiveMult = 30000334171948800;}
else if(dayDiff >= 14520){incentiveMult = 30000333966382900;}
else if(dayDiff >= 14490){incentiveMult = 30000333743247500;}
else if(dayDiff >= 14460){incentiveMult = 30000333501095400;}
else if(dayDiff >= 14430){incentiveMult = 30000333238364900;}
else if(dayDiff >= 14400){incentiveMult = 30000332953371400;}

        return incentiveMult;
    }
    function getYear50(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 17970){incentiveMult = 30000336497334400;}
else if(dayDiff >= 17940){incentiveMult = 30000336497330300;}
else if(dayDiff >= 17910){incentiveMult = 30000336497325700;}
else if(dayDiff >= 17880){incentiveMult = 30000336497320700;}
else if(dayDiff >= 17850){incentiveMult = 30000336497315000;}
else if(dayDiff >= 17820){incentiveMult = 30000336497308700;}
else if(dayDiff >= 17790){incentiveMult = 30000336497301700;}
else if(dayDiff >= 17760){incentiveMult = 30000336497294000;}
else if(dayDiff >= 17730){incentiveMult = 30000336497285300;}
else if(dayDiff >= 17700){incentiveMult = 30000336497275700;}
else if(dayDiff >= 17670){incentiveMult = 30000336497265000;}
else if(dayDiff >= 17640){incentiveMult = 30000336497253100;}
else if(dayDiff >= 17610){incentiveMult = 30000336497239900;}
else if(dayDiff >= 17580){incentiveMult = 30000336497225200;}
else if(dayDiff >= 17550){incentiveMult = 30000336497208900;}
else if(dayDiff >= 17520){incentiveMult = 30000336497190800;}
else if(dayDiff >= 17490){incentiveMult = 30000336497170700;}
else if(dayDiff >= 17460){incentiveMult = 30000336497148400;}
else if(dayDiff >= 17430){incentiveMult = 30000336497123600;}
else if(dayDiff >= 17400){incentiveMult = 30000336497096200;}
else if(dayDiff >= 17370){incentiveMult = 30000336497065700;}
else if(dayDiff >= 17340){incentiveMult = 30000336497031900;}
else if(dayDiff >= 17310){incentiveMult = 30000336496994500;}
else if(dayDiff >= 17280){incentiveMult = 30000336496953000;}
else if(dayDiff >= 17250){incentiveMult = 30000336496907000;}
else if(dayDiff >= 17220){incentiveMult = 30000336496856000;}
else if(dayDiff >= 17190){incentiveMult = 30000336496799600;}
else if(dayDiff >= 17160){incentiveMult = 30000336496737100;}
else if(dayDiff >= 17130){incentiveMult = 30000336496667900;}
else if(dayDiff >= 17100){incentiveMult = 30000336496591300;}
else if(dayDiff >= 17070){incentiveMult = 30000336496506500;}
else if(dayDiff >= 17040){incentiveMult = 30000336496412700;}
else if(dayDiff >= 17010){incentiveMult = 30000336496308900;}
else if(dayDiff >= 16980){incentiveMult = 30000336496194200;}
else if(dayDiff >= 16950){incentiveMult = 30000336496067300;}
else if(dayDiff >= 16920){incentiveMult = 30000336495927000;}
else if(dayDiff >= 16890){incentiveMult = 30000336495772000;}
else if(dayDiff >= 16860){incentiveMult = 30000336495600700;}
else if(dayDiff >= 16830){incentiveMult = 30000336495411500;}
else if(dayDiff >= 16800){incentiveMult = 30000336495202500;}
else if(dayDiff >= 16770){incentiveMult = 30000336494971800;}
else if(dayDiff >= 16740){incentiveMult = 30000336494717000;}
else if(dayDiff >= 16710){incentiveMult = 30000336494435900;}
else if(dayDiff >= 16680){incentiveMult = 30000336494125700;}
else if(dayDiff >= 16650){incentiveMult = 30000336493783400;}
else if(dayDiff >= 16620){incentiveMult = 30000336493405900;}
else if(dayDiff >= 16590){incentiveMult = 30000336492989700;}
else if(dayDiff >= 16560){incentiveMult = 30000336492530800;}
else if(dayDiff >= 16530){incentiveMult = 30000336492025000;}
else if(dayDiff >= 16500){incentiveMult = 30000336491467600;}
else if(dayDiff >= 16470){incentiveMult = 30000336490853600;}
else if(dayDiff >= 16440){incentiveMult = 30000336490177200;}
else if(dayDiff >= 16410){incentiveMult = 30000336489432400;}
else if(dayDiff >= 16380){incentiveMult = 30000336488612400;}
else if(dayDiff >= 16350){incentiveMult = 30000336487709800;}
else if(dayDiff >= 16320){incentiveMult = 30000336486716500;}
else if(dayDiff >= 16290){incentiveMult = 30000336485623600;}
else if(dayDiff >= 16260){incentiveMult = 30000336484421500;}
else if(dayDiff >= 16230){incentiveMult = 30000336483099600;}
else if(dayDiff >= 16200){incentiveMult = 30000336481646100;}

        return incentiveMult;
    }
    function getYear55(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        if(dayDiff >= 19770){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19740){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19710){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19680){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19650){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19620){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19590){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19560){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19530){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19500){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19470){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19440){incentiveMult = 30000336497369500;}
else if(dayDiff >= 19410){incentiveMult = 30000336497369500;}
else if(dayDiff >= 19380){incentiveMult = 30000336497369500;}
else if(dayDiff >= 19350){incentiveMult = 30000336497369500;}
else if(dayDiff >= 19320){incentiveMult = 30000336497369500;}
else if(dayDiff >= 19290){incentiveMult = 30000336497369400;}
else if(dayDiff >= 19260){incentiveMult = 30000336497369400;}
else if(dayDiff >= 19230){incentiveMult = 30000336497369400;}
else if(dayDiff >= 19200){incentiveMult = 30000336497369300;}
else if(dayDiff >= 19170){incentiveMult = 30000336497369300;}
else if(dayDiff >= 19140){incentiveMult = 30000336497369300;}
else if(dayDiff >= 19110){incentiveMult = 30000336497369200;}
else if(dayDiff >= 19080){incentiveMult = 30000336497369100;}
else if(dayDiff >= 19050){incentiveMult = 30000336497369100;}
else if(dayDiff >= 19020){incentiveMult = 30000336497369000;}
else if(dayDiff >= 18990){incentiveMult = 30000336497368900;}
else if(dayDiff >= 18960){incentiveMult = 30000336497368800;}
else if(dayDiff >= 18930){incentiveMult = 30000336497368700;}
else if(dayDiff >= 18900){incentiveMult = 30000336497368600;}
else if(dayDiff >= 18870){incentiveMult = 30000336497368500;}
else if(dayDiff >= 18840){incentiveMult = 30000336497368300;}
else if(dayDiff >= 18810){incentiveMult = 30000336497368200;}
else if(dayDiff >= 18780){incentiveMult = 30000336497368000;}
else if(dayDiff >= 18750){incentiveMult = 30000336497367800;}
else if(dayDiff >= 18720){incentiveMult = 30000336497367600;}
else if(dayDiff >= 18690){incentiveMult = 30000336497367300;}
else if(dayDiff >= 18660){incentiveMult = 30000336497367000;}
else if(dayDiff >= 18630){incentiveMult = 30000336497366700;}
else if(dayDiff >= 18600){incentiveMult = 30000336497366300;}
else if(dayDiff >= 18570){incentiveMult = 30000336497365900;}
else if(dayDiff >= 18540){incentiveMult = 30000336497365500;}
else if(dayDiff >= 18510){incentiveMult = 30000336497365000;}
else if(dayDiff >= 18480){incentiveMult = 30000336497364400;}
else if(dayDiff >= 18450){incentiveMult = 30000336497363800;}
else if(dayDiff >= 18420){incentiveMult = 30000336497363000;}
else if(dayDiff >= 18390){incentiveMult = 30000336497362200;}
else if(dayDiff >= 18360){incentiveMult = 30000336497361400;}
else if(dayDiff >= 18330){incentiveMult = 30000336497360400;}
else if(dayDiff >= 18300){incentiveMult = 30000336497359300;}
else if(dayDiff >= 18270){incentiveMult = 30000336497358000;}
else if(dayDiff >= 18240){incentiveMult = 30000336497356700;}
else if(dayDiff >= 18210){incentiveMult = 30000336497355100;}
else if(dayDiff >= 18180){incentiveMult = 30000336497353400;}
else if(dayDiff >= 18150){incentiveMult = 30000336497351500;}
else if(dayDiff >= 18120){incentiveMult = 30000336497349400;}
else if(dayDiff >= 18090){incentiveMult = 30000336497347000;}
else if(dayDiff >= 18060){incentiveMult = 30000336497344300;}
else if(dayDiff >= 18030){incentiveMult = 30000336497341400;}
else if(dayDiff >= 18000){incentiveMult = 30000336497338100;}

        return incentiveMult;
    }
    function getYear60(int dayDiff) internal pure returns (int256) {
        int incentiveMult = 0;
        
if(dayDiff >= 19950){incentiveMult = 30000336497369700;}
else if(dayDiff >= 19920){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19890){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19860){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19830){incentiveMult = 30000336497369600;}
else if(dayDiff >= 19800){incentiveMult = 30000336497369600;}

        return incentiveMult;
    }
}