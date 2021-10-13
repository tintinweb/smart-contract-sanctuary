// SPDX-License-Identifier: MIT

/// @title Places drop with starting index 0

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPlacesDrop} from "../interfaces/IPlacesDrop.sol";

contract PlacesDrop0 is IPlacesDrop, Ownable {
    address payable private dropTreasury;
    uint256 private startingIndex;
    string[12][50] private places = [
        [
            unicode"Brooklyn Bridge",
            unicode"Brooklyn Bridge",
            unicode"DUMBO",
            unicode"New York",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Historic Landmark",
            unicode"Suspension Bridge",
            unicode"Pedestrian Bridge"
        ],
        [
            unicode"Cozy Royale",
            unicode"434 Humboldt St",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11211",
            unicode"US",
            unicode"Burgers",
            unicode"Outdoors / Patio",
            unicode"Craft Beer"
        ],
        [
            unicode"MAISON du TSURU",
            unicode"428 Humboldt St",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11211",
            unicode"US",
            unicode"Coffee Shop",
            unicode"Matcha",
            unicode"Croissants"
        ],
        [
            unicode"Pheasant",
            unicode"445 Graham Ave",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11211",
            unicode"US",
            unicode"Mediterranean Cuisine",
            unicode"Wine Bar",
            unicode"Outdoors / Patio"
        ],
        [
            unicode"Peter Luger Steak House",
            unicode"178 Broadway",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11211",
            unicode"US",
            unicode"Steakhouse",
            unicode"Business Lunch",
            unicode"Butcher"
        ],
        [
            unicode"Sunshine Laundromat & Pinball",
            unicode"860 Manhattan Ave",
            unicode"Greenpoint",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11222",
            unicode"US",
            unicode"Laundromat",
            unicode"Pinball",
            unicode"Craft Beer"
        ],
        [
            unicode"June Wine Bar",
            unicode"231 Court St",
            unicode"Carroll Gardens",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Natural Wine",
            unicode"Date Night",
            unicode"Outdoors / Patio"
        ],
        [
            unicode"Malai",
            unicode"268 Smith St",
            unicode"Carroll Gardens",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11231",
            unicode"US",
            unicode"Artisanal Ice Cream",
            unicode"Women-Owned",
            unicode""
        ],
        [
            unicode"Japanese Hill-and-Pond Garden",
            unicode"990 Washington Ave",
            unicode"Prospect Park",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11225",
            unicode"US",
            unicode"Japanese Garden",
            unicode"Pond",
            unicode"Shrine"
        ],
        [
            unicode"Dekalb Market Hall",
            unicode"445 Albee Square West",
            unicode"Downtown Brooklyn",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Food Hall",
            unicode"Global Cuisine",
            unicode"Live Events"
        ],
        [
            unicode"Pig Beach",
            unicode"480 Union St",
            unicode"Gowanus",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11231",
            unicode"US",
            unicode"BBQ",
            unicode"Burgers",
            unicode"Outdoors / Patio"
        ],
        [
            unicode"Public Records",
            unicode"233 Butler St",
            unicode"Gowanus",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11217",
            unicode"US",
            unicode"Dancehall",
            unicode"Wine Bar",
            unicode"Vegan"
        ],
        [
            unicode"Royal Palms Shuffleboard Club",
            unicode"514 Union St",
            unicode"Gowanus",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11215",
            unicode"US",
            unicode"Shuffleboard",
            unicode"Tropical Cocktails",
            unicode"Food Truck Park"
        ],
        [
            unicode"The Green-Wood Cemetery",
            unicode"500 25th St",
            unicode"Green - Wood Cemetery",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11232",
            unicode"US",
            unicode"Cemetery",
            unicode"Walking Path",
            unicode"Historic Landmark"
        ],
        [
            unicode"Williamsburg Bridge",
            unicode"Williamsburg Bridge",
            unicode"Manhattan",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"10002",
            unicode"US",
            unicode"Suspension Bridge",
            unicode"Pedestrian Bridge",
            unicode"Bike Trail"
        ],
        [
            unicode"Brooklyn Museum",
            unicode"200 Eastern Pkwy",
            unicode"Prospect Park",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11238",
            unicode"US",
            unicode"Art Museum",
            unicode"Beaux-Arts",
            unicode"Sculpture Garden"
        ],
        [
            unicode"Brooklyn Navy Yard",
            unicode"63 Flushing Ave",
            unicode"Brooklyn Navy Yard",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11205",
            unicode"US",
            unicode"Industrial Park",
            unicode"Shipyard",
            unicode"Historic Landmark"
        ],
        [
            unicode"The Naval Cemetery Landscape",
            unicode"63 Williamsburg St W",
            unicode"Brooklyn Navy Yard",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11249",
            unicode"US",
            unicode"Urban Green Space",
            unicode"Walking Path",
            unicode"Nature Preserve"
        ],
        [
            unicode"Brooklyn Academy of Music (BAM)",
            unicode"30 Lafayette Ave",
            unicode"Fort Greene",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11217",
            unicode"US",
            unicode"Opera House",
            unicode"Theater",
            unicode"Renaissance Revival"
        ],
        [
            unicode"Hendrick I. Lott House",
            unicode"1940 E 36th St",
            unicode"Marine Park",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11234",
            unicode"US",
            unicode"Historic House",
            unicode"Historic Landmark",
            unicode"Dutch Colonial"
        ],
        [
            unicode"The Boathouse & Audubon Center",
            unicode"95 Prospect Park W",
            unicode"Prospect Park",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11215",
            unicode"US",
            unicode"Historic Landmark",
            unicode"Beaux-Arts",
            unicode"Event Space"
        ],
        [
            unicode"Center for Brooklyn History",
            unicode"128 Pierrepont St",
            unicode"Brooklyn Heights",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"History Museum",
            unicode"Library",
            unicode"Historic Landmark"
        ],
        [
            unicode"New York Transit Museum",
            unicode"99 Schermerhorn St",
            unicode"Downtown Brooklyn",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Museum",
            unicode"Subway",
            unicode"Gift Shop"
        ],
        [
            unicode"Old Stone House & Washington Park",
            unicode"336 3rd St",
            unicode"Park Slope",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11215",
            unicode"US",
            unicode"Historic House",
            unicode"Museum",
            unicode"Garden"
        ],
        [
            unicode"Wyckoff House Museum",
            unicode"5816 Clarendon Rd",
            unicode"Canarsie",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11203",
            unicode"US",
            unicode"Historic House",
            unicode"Museum",
            unicode"Garden"
        ],
        [
            unicode"Domino Sugar Refinery",
            unicode"292 Kent Ave",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11222",
            unicode"US",
            unicode"Factory",
            unicode"Historic Landmark",
            unicode"Office Park"
        ],
        [
            unicode"Maimonides Park",
            unicode"1904 Surf Ave",
            unicode"Coney Island",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11224",
            unicode"US",
            unicode"Hot Dogs",
            unicode"Baseball Stadium",
            unicode"Statue"
        ],
        [
            unicode"The Hoxton, Williamsburg",
            unicode"97 Wythe Ave",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11249",
            unicode"US",
            unicode"Hotel",
            unicode"Rooftop Bar",
            unicode"Event Space"
        ],
        [
            unicode"The Williamsburg Hotel",
            unicode"96 Wythe Ave",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11249",
            unicode"US",
            unicode"Hotel",
            unicode"Lobby Bar",
            unicode"Rooftop Pool"
        ],
        [
            unicode"Domino Park",
            unicode"300 Kent Ave",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11249",
            unicode"US",
            unicode"Park",
            unicode"Playground",
            unicode"Superstamp"
        ],
        [
            unicode"Brooklyn Bridge Park",
            unicode"334 Furman St",
            unicode"Brooklyn Heights",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Park",
            unicode"Superstamp",
            unicode"Playground"
        ],
        [
            unicode"Adam Yauch Park",
            unicode"21 State St",
            unicode"Brooklyn Heights",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Park",
            unicode"Basketball Court",
            unicode"Dog Park"
        ],
        [
            unicode"Brooklyn Bridge Park – Pier 5",
            unicode"268 Furman St",
            unicode"Brooklyn Heights",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Soccer Field",
            unicode"Park",
            unicode"Pier"
        ],
        [
            unicode"Brooklyn Bridge Park – Pier 3",
            unicode"Furman St",
            unicode"Brooklyn Heights",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"10004",
            unicode"US",
            unicode"Pier",
            unicode"Labyrinth",
            unicode"Picnic Area"
        ],
        [
            unicode"Fort Greene Park",
            unicode"100 Washington Park",
            unicode"Fort Greene",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Park",
            unicode"Walking Path",
            unicode"Crypt"
        ],
        [
            unicode"Prospect Park",
            unicode"95 Prospect Park W",
            unicode"Prospect Park",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11215",
            unicode"US",
            unicode"Park",
            unicode"Lake",
            unicode"Meadow"
        ],
        [
            unicode"Commodore Barry Park",
            unicode"19 N Elliot Pl",
            unicode"Fort Greene",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"Park",
            unicode"Baseball Field",
            unicode"Public pool"
        ],
        [
            unicode"Marine Park",
            unicode"Brooklyn NY 11229",
            unicode"Marine Park",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11229",
            unicode"US",
            unicode"Park",
            unicode"Marsh",
            unicode"Nature Preserve"
        ],
        [
            unicode"Sunset Park",
            unicode"4200 Seventh Ave",
            unicode"Sunset Park",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11232",
            unicode"US",
            unicode"Park",
            unicode"Scenic Lookout",
            unicode"Playground"
        ],
        [
            unicode"Owl's Head Park",
            unicode"68 Colonial Ct",
            unicode"Bay Ridge",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11220",
            unicode"US",
            unicode"Park",
            unicode"Skate Park",
            unicode"Dog Park"
        ],
        [
            unicode"The HiHi Room",
            unicode"138 Smith St",
            unicode"Boerum Hill",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11201",
            unicode"US",
            unicode"New American Cuisine",
            unicode"Burgers",
            unicode"Brunch"
        ],
        [
            unicode"Win Son",
            unicode"159 Graham Ave",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11206",
            unicode"US",
            unicode"Taiwanese Cuisine",
            unicode"Brunch",
            unicode"Cocktails"
        ],
        [
            unicode"Win Son Bakery",
            unicode"164 Graham Ave",
            unicode"Williamsburg",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11206",
            unicode"US",
            unicode"Bakery",
            unicode"Taiwanese Cuisine",
            unicode"Café"
        ],
        [
            unicode"Terrace Bagels",
            unicode"222 & 222A Prospect Park",
            unicode"Windsor Terrace",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11215",
            unicode"US",
            unicode"Bagels",
            unicode"Deli",
            unicode"Bakery"
        ],
        [
            unicode"Bagel Hole",
            unicode"400 Seventh Ave",
            unicode"South Slope",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11215",
            unicode"US",
            unicode"Bagels",
            unicode"Sandwiches",
            unicode"Tiny Space"
        ],
        [
            unicode"Tasty Bagels",
            unicode"1705 86th St",
            unicode"Bath Beach",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11214",
            unicode"US",
            unicode"Bagels",
            unicode"Sandwiches",
            unicode"Wraps"
        ],
        [
            unicode"Industry City Food Hall",
            unicode"220 36th St",
            unicode"Sunset Park",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11232",
            unicode"US",
            unicode"Food Hall",
            unicode"Event Space",
            unicode"Industrial Park"
        ],
        [
            unicode"Frank’s Wine Bar",
            unicode"465 Court St",
            unicode"Carroll Gardens",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11231",
            unicode"US",
            unicode"Wine Bar",
            unicode"Small Bites",
            unicode"Date Night"
        ],
        [
            unicode"F&F Pizzeria",
            unicode"459 Court St",
            unicode"Carroll Gardens",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11231",
            unicode"US",
            unicode"Pizza",
            unicode"Grab-and-Go",
            unicode""
        ],
        [
            unicode"Emily",
            unicode"919 Fulton St",
            unicode"Clinton Hill",
            unicode"Brooklyn",
            unicode"Kings",
            unicode"NY",
            unicode"United States",
            unicode"11238",
            unicode"US",
            unicode"Pizza",
            unicode"Burgers",
            unicode"Date Night"
        ]
    ];

    string[3][50] private locations = [
        ["40.70599315692884", "-73.99669746224953", "0.00000000000000"],
        ["40.71694024673527", "-73.94290290996189", "10.00000000000000"],
        ["40.71655438067324", "-73.94287664571932", "15.00000000000000"],
        ["40.71849066677341", "-73.94522193992641", "6.00000000000000"],
        ["40.709835887780564", "-73.96252523769478", "18.00000000000000"],
        ["40.72926351184816", "-73.95370808862016", "9.00000000000000"],
        ["40.68607206267459", "-73.99393064373557", "16.00000000000000"],
        ["40.682661900574566", "-73.99337662043752", "9.00000000000000"],
        ["40.66861598622139", "-73.96310152061812", "45.00000000000000"],
        ["40.69059031783411", "-73.98294927513967", "20.00000000000000"],
        ["40.67958146499482", "-73.98895672499302", "4.00000000000000"],
        ["40.6820997974222", "-73.9864785049527", "2.00000000000000"],
        ["40.678539059956066", "-73.98700069834821", "7.00000000000000"],
        ["40.65286242844665", "-73.99021136212338", "57.00000000000000"],
        ["40.71346960712147", "-73.97183759878888", "0.00000000000000"],
        ["40.67123349730922", "-73.96372645159755", "54.00000000000000"],
        ["40.69936040648695", "-73.97416555325366", "8.00000000000000"],
        ["40.69913146952489", "-73.96291995192072", "7.00000000000000"],
        ["40.686460503819056", "-73.97769552370784", "19.00000000000000"],
        ["40.61042516224416", "-73.9325925906108", "5.00000000000000"],
        ["40.66080569848738", "-73.96527413850549", "29.00000000000000"],
        ["40.694858498810014", "-73.99243982972655", "42.00000000000000"],
        ["40.69062118478285", "-73.98994373769717", "32.00000000000000"],
        ["40.672991090235044", "-73.98460721969114", "11.00000000000000"],
        ["40.64435664490109", "-73.9207884948798", "4.00000000000000"],
        ["40.71437477225805", "-73.96718714768494", "13.00000000000000"],
        ["40.57441003658539", "-73.98415732480893", "0.00000000000000"],
        ["40.720789097730126", "-73.95881966686758", "15.00000000000000"],
        ["40.721469682088674", "-73.95873629976903", "8.00000000000000"],
        ["40.714095871783364", "-73.96822631437904", "13.00000000000000"],
        ["40.69919782771749", "-73.99725323004498", "17.00000000000000"],
        ["40.69204649953526", "-73.9989125704394", "10.00000000000000"],
        ["40.69487140051072", "-74.00173554355074", "4.00000000000000"],
        ["40.69789566708734", "-73.99949782668448", "1.00000000000000"],
        ["40.69144819793023", "-73.97545524427632", "24.00000000000000"],
        ["40.66257167767023", "-73.96808253392824", "49.00000000000000"],
        ["40.69727278369864", "-73.97891522533786", "2.00000000000000"],
        ["40.5981092082718", "-73.9209978653736", "-3.00000000000000"],
        ["40.647931668088006", "-74.00377086921706", "47.00000000000000"],
        ["40.639702542532056", "-74.03192053233445", "24.00000000000000"],
        ["40.68708682542225", "-73.99036093138795", "9.00000000000000"],
        ["40.70745749598716", "-73.94344452139445", "12.00000000000000"],
        ["40.70720527839589", "-73.94298960393672", "12.00000000000000"],
        ["40.660055121688", "-73.98087478206361", "52.00000000000000"],
        ["40.664838394665324", "-73.98352565068006", "36.00000000000000"],
        ["40.608599284347136", "-74.004472465824", "12.00000000000000"],
        ["40.65608427933295", "-74.00813128728387", "11.00000000000000"],
        ["40.67717515434986", "-73.998215576301", "14.00000000000000"],
        ["40.677307261313764", "-73.99814905651522", "14.00000000000000"],
        ["40.68352477545822", "-73.96642152915108", "26.00000000000000"]
    ];

    int256[3][50] private locationsInt = [
        [
            int256(4070599315692884),
            int256(-73996697462249536),
            int256(0.00000000000000)
        ],
        [
            int256(4071694024673527),
            int256(-73942902909961888),
            int256(10.00000000000000)
        ],
        [
            int256(4071655438067323),
            int256(-73942876645719328),
            int256(15.00000000000000)
        ],
        [
            int256(4071849066677341),
            int256(-73945221939926416),
            int256(6.00000000000000)
        ],
        [
            int256(4070983588778056),
            int256(-73962525237694784),
            int256(18.00000000000000)
        ],
        [
            int256(4072926351184816),
            int256(-73953708088620160),
            int256(9.00000000000000)
        ],
        [
            int256(4068607206267459),
            int256(-73993930643735568),
            int256(16.00000000000000)
        ],
        [
            int256(4068266190057456),
            int256(-73993376620437520),
            int256(9.00000000000000)
        ],
        [
            int256(4066861598622139),
            int256(-73963101520618128),
            int256(45.00000000000000)
        ],
        [
            int256(4069059031783411),
            int256(-73982949275139680),
            int256(20.00000000000000)
        ],
        [
            int256(4067958146499482),
            int256(-73988956724993024),
            int256(4.00000000000000)
        ],
        [
            int256(4068209979742219),
            int256(-73986478504952704),
            int256(2.00000000000000)
        ],
        [
            int256(4067853905995606),
            int256(-73987000698348208),
            int256(7.00000000000000)
        ],
        [
            int256(4065286242844665),
            int256(-73990211362123376),
            int256(57.00000000000000)
        ],
        [
            int256(4071346960712147),
            int256(-73971837598788880),
            int256(0.00000000000000)
        ],
        [
            int256(4067123349730921),
            int256(-73963726451597552),
            int256(54.00000000000000)
        ],
        [
            int256(4069936040648695),
            int256(-73974165553253648),
            int256(8.00000000000000)
        ],
        [
            int256(4069913146952489),
            int256(-73962919951920720),
            int256(7.00000000000000)
        ],
        [
            int256(4068646050381905),
            int256(-73977695523707840),
            int256(19.00000000000000)
        ],
        [
            int256(4061042516224416),
            int256(-73932592590610800),
            int256(5.00000000000000)
        ],
        [
            int256(4066080569848738),
            int256(-73965274138505488),
            int256(29.00000000000000)
        ],
        [
            int256(4069485849881001),
            int256(-73992439829726544),
            int256(42.00000000000000)
        ],
        [
            int256(4069062118478285),
            int256(-73989943737697168),
            int256(32.00000000000000)
        ],
        [
            int256(4067299109023504),
            int256(-73984607219691136),
            int256(11.00000000000000)
        ],
        [
            int256(4064435664490108),
            int256(-73920788494879808),
            int256(4.00000000000000)
        ],
        [
            int256(4071437477225804),
            int256(-73967187147684944),
            int256(13.00000000000000)
        ],
        [
            int256(4057441003658539),
            int256(-73984157324808928),
            int256(0.00000000000000)
        ],
        [
            int256(4072078909773012),
            int256(-73958819666867584),
            int256(15.00000000000000)
        ],
        [
            int256(4072146968208867),
            int256(-73958736299769024),
            int256(8.00000000000000)
        ],
        [
            int256(4071409587178336),
            int256(-73968226314379040),
            int256(13.00000000000000)
        ],
        [
            int256(4069919782771749),
            int256(-73997253230044976),
            int256(17.00000000000000)
        ],
        [
            int256(4069204649953526),
            int256(-73998912570439408),
            int256(10.00000000000000)
        ],
        [
            int256(4069487140051072),
            int256(-74001735543550736),
            int256(4.00000000000000)
        ],
        [
            int256(4069789566708733),
            int256(-73999497826684480),
            int256(1.00000000000000)
        ],
        [
            int256(4069144819793023),
            int256(-73975455244276320),
            int256(24.00000000000000)
        ],
        [
            int256(4066257167767023),
            int256(-73968082533928240),
            int256(49.00000000000000)
        ],
        [
            int256(4069727278369863),
            int256(-73978915225337856),
            int256(2.00000000000000)
        ],
        [
            int256(4059810920827180),
            int256(-73920997865373600),
            int256(-3.00000000000000)
        ],
        [
            int256(4064793166808800),
            int256(-74003770869217056),
            int256(47.00000000000000)
        ],
        [
            int256(4063970254253205),
            int256(-74031920532334448),
            int256(24.00000000000000)
        ],
        [
            int256(4068708682542225),
            int256(-73990360931387952),
            int256(9.00000000000000)
        ],
        [
            int256(4070745749598715),
            int256(-73943444521394448),
            int256(12.00000000000000)
        ],
        [
            int256(4070720527839589),
            int256(-73942989603936720),
            int256(12.00000000000000)
        ],
        [
            int256(4066005512168800),
            int256(-73980874782063616),
            int256(52.00000000000000)
        ],
        [
            int256(4066483839466532),
            int256(-73983525650680064),
            int256(36.00000000000000)
        ],
        [
            int256(4060859928434713),
            int256(-74004472465824000),
            int256(12.00000000000000)
        ],
        [
            int256(4065608427933295),
            int256(-74008131287283872),
            int256(11.00000000000000)
        ],
        [
            int256(4067717515434986),
            int256(-73998215576301008),
            int256(14.00000000000000)
        ],
        [
            int256(4067730726131376),
            int256(-73998149056515216),
            int256(14.00000000000000)
        ],
        [
            int256(4068352477545821),
            int256(-73966421529151072),
            int256(26.00000000000000)
        ]
    ];

    constructor(uint256 _startingIndex, address payable _dropTreasury) {
        startingIndex = _startingIndex;
        dropTreasury = _dropTreasury;
    }

    function getTreasury() external view override returns (address payable) {
        return dropTreasury;
    }

    function getPlaceCount() external view override returns (uint256) {
        return places.length;
    }

    function getEndingIndex() external view override returns (uint256) {
        return startingIndex + places.length - 1;
    }

    function getPlace(uint256 tokenId)
        external
        view
        override
        returns (Place memory)
    {
        uint256 index = tokenId - startingIndex;
        require(index >= startingIndex, "Token is out of range.");
        require(index < places.length, "Token is out of places range.");
        require(index < locations.length, "Token is out of locations range.");
        require(
            index < locationsInt.length,
            "Token out of locations integer range."
        );

        string[12] memory _place = places[index];
        string[3] memory _location = locations[index];
        int256[3] memory _locationInt = locationsInt[index];

        Place memory place = Place(
            _place[0],
            _place[1],
            _place[2],
            _place[3],
            _place[4],
            _place[5],
            _place[6],
            _place[7],
            _place[8],
            Location(
                _locationInt[0],
                _locationInt[1],
                _locationInt[2],
                true,
                _location[0],
                _location[1],
                _location[2]
            ),
            [_place[9], _place[10], _place[11]]
        );
        return place;
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Places drop

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

interface IPlacesDrop {
    /**
     * @notice Represents a 3D geographical coordinate with altitude.
     */
    struct Location {
        int256 latitudeInt;
        int256 longitudeInt;
        int256 altitudeInt;
        bool hasAltitude;
        string latitude;
        string longitude;
        string altitude;
    }

    /**
     * @notice Represents place information for a geographic location.
     */
    struct Place {
        string name;
        string streetAddress;
        string sublocality;
        string locality;
        string subadministrativeArea;
        string administrativeArea;
        string country;
        string postalCode;
        string countryCode;
        Location location;
        string[3] attributes;
    }

    function getTreasury() external view returns (address payable);

    function getPlaceCount() external view returns (uint256);

    function getEndingIndex() external view returns (uint256);

    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlacesDrop.Place memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}