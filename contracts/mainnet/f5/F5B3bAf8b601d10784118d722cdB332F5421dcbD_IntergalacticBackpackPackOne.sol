// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/math/SafeMath.sol";
import "@openzeppelin/[email protected]/utils/math/Math.sol";
import "@openzeppelin/[email protected]/utils/Arrays.sol";

contract IntergalacticBackpackPackOne is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    uint256 public constant M = 3500;

    uint256 public constant R = 10;

    uint256 private y = 35000000000000000; // 0.035 Ether

    // Worlds with cateogory items

    // WORLD: wwd56rt7io

    // Allies
    // string[] public worldwwd56rt7ioAllies = ["MakMak Jumper","wwrtdy sumbetrin","rrarra kashefi","mestia the burrower","oracle vansilla"];

    // Nemeses
    // string[] public worldwwd56rt7ioNemeses = ["aragon tenvis lords","inkatheis MakMak killers","pattri mites","svanves mutila","wwwi895 Destroyer Gravity Caterpillars"];

    // Damage / Intoxication
    // string[] public worldwwd56rt7ioDamageIntoxication = ["phesis dirt burial","ww783av rock collision","Snasis Leaf cuts","e8889 dust storm","q21i aluminum shard wind"];

    // Weapons / Communication
    // string[] public worldwwd56rt7ioWeaponsCommunication = ["ww509sen contraction rope","dimensional hypothesis axe","nebula dust chemtrail gun","Venchibu Model4T9 Galactic Dialer","vanesis thorn blade"];

    // Shields / Protection
    // string[] public worldwwd56rt7ioShieldsProtection = ["wqwq7T569 MakMak military net","keshvin concurrency modulation shroud","aluminium wwi894t charge deflection suit","muskrate syrum","DEFINITIS ILLUSION LIGHT"];

    // Surrounding Space / Bases
    // string[] public worldwwd56rt7ioSurroundingSpaceBases = ["Jinfara Moon w4","vansilla extradition camp","MakMak asteroid","ww7984rhk blackhole","pattri space bile"];

    // Landscape / Beings / Creatures
    // string[] public worldwwd56rt7ioLandscapeBeingsCreatures = ["www8CXa dirt fields","poliaki moss eaters","0009a moon dust debris","blue avakalon ice condors","wind consuming mukahs"];

    // Currency / Assets
    // string[] public worldwwd56rt7ioCurrencyAssets = [".000089 www89",".14765 www90","mutila dark emeralds x 14","sonalis gateway key",".00034 pestriaks"];

    // Transportation
    // string[] public worldwwd56rt7ioTransportation = ["Stam Drill","reverse Mulkano crawler","opaque 222iTFKC ground divider","MakMak dust shoes","k6k6 dust propelled moon shuttle"];

    // Intergalactic Backpack
    // string[] public worldwwd56rt7ioIntergalacticBackpack = ["The Dust Times Weekly Sunday Magazine","Juibatik Science Center Poker Cards","www4vas Boba House Loyalty Card","Jinfara Moon Brand Sugarfree Cough Drops","Snasis Leaf Anti-Allergy Tablets"];


    // WORLD: Alycora

    // Allies
    // string[] public worldAlycoraAllies = ["Kesif (Thamaran Prisoner)","Mulaka Avantaris (Thamarian Prisoner)","Rika 34724 (Escaped Thamarian Guard)","Sonkelis","Matrivi"];

    // Nemeses
    // string[] public worldAlycoraNemeses = ["Thamaran Cognition Serpent","Aleros","Juvabis Destruction Beast","The Antakela","Rika Seba 84003 (Thamarian Leader)"];

    // Damage / Intoxication
    // string[] public worldAlycoraDamageIntoxication = ["Menkra Heat Burns","Palladium Intoxication","Eviscerating Blade of Thekatis","Thamarian Illusionary Pollen","Centril Dust"];

    // Weapons / Communication
    // string[] public worldAlycoraWeaponsCommunication = ["Menkra Heat Gun","Palladium Dagger","Woltron Dimensional Stone","Ando World Dialer","Metisa Cosmic Relay"];

    // Shields / Protection
    // string[] public worldAlycoraShieldsProtection = ["Cobalt Protection Suit","Artila Deflection Force","Festa Asteroid Blaster","Thamarian Energy Disperser","Ulla Darkmatter Suit"];

    // Surrounding Space / Bases
    // string[] public worldAlycoraSurroundingSpaceBases = ["J56R (Moon of Mesaesis)","Tolla 4 (Thamarian Base)","Tolla 5 (Thamarian Base)","Hafra 26 (Moon of the Thamarian Senate)","Galla 9 (Meteor)"];

    // Landscape / Beings / Creatures
    // string[] public worldAlycoraLandscapeBeingsCreatures = ["Wild Rutherian Drinkers","Tevita Hills","Rhenium Valley","Visionary of Effa (Being)","The Tronitii"];

    // Currency / Assets
    // string[] public worldAlycoraCurrencyAssets = ["84 Peka Shells","Misalik Tokens x 14.57","Bag of Terbium","Promethium Squares","0.00067 Tankil Bars"];

    // Transportation
    // string[] public worldAlycoraTransportation = ["Seffa Cruiser","Venki Surface Ejector","Thamarian Wind Glider","Chlorine Sea Hover Circle","Fastril Nebula Parachute"];

    // Intergalactic Backpack
    // string[] public worldAlycoraIntergalacticBackpack = ["Inter-nebular University Never-Dry Hi-Liter","One Uff Performance Quantum Quick Dry Sock","Tronitii Brand Heffa Bean Snacks","Exabyte Conversation Memory Headphones","Juicy Cosmic Ultra Mint Gum Wrapper"];


    // WORLD: Lusellas

    // Allies
    // string[] public worldLusellasAllies = ["#FEEB99 (Lusellain Being)","#F8EDDC (Lusellain Being)","#EDC5E4 (Lusellain Being)","#EDBEC8 (Lusellain Being)","#FDDAE3 (Lusellain Being)"];

    // Nemeses
    // string[] public worldLusellasNemeses = ["#E1C2D9 (Lusellain Being)","#AEA7D1 (Lusellain Being)","#B8B1C1 (Lusellain Being)","#C3A2BF (Lusellain Being)","#978BC4 (Lusellain Being)"];

    // Damage / Intoxication
    // string[] public worldLusellasDamageIntoxication = ["Lusela Color Deterioration Attack","Nvarisa Palette Transformation","Black and White Confinement","Vesin Gamma Blast","Gyroscopic Deterioration"];

    // Weapons / Communication
    // string[] public worldLusellasWeaponsCommunication = ["Jekka Palette","#F1C470 Blast","#FECBA5 Disorientation Orbs","#76CBF0 Drowning Blaster","#FFCADD Intoxicator"];

    // Shields / Protection
    // string[] public worldLusellasShieldsProtection = ["#B9DFD4 Biogenetic Shield","#F7CDEC Photon Resistant Chamber","#D4C6F5 Deflection Blades","#FFF7D1 Trajectory Reversal Chamber","Radiuum Body Circle"];

    // Surrounding Space / Bases
    // string[] public worldLusellasSurroundingSpaceBases = ["Vurra Atmospheric Escape Stairs","#C9E9F5 Moon","#E1F5F3 Comet","Asterids of Angeris","Lessi Resistance Orbital Fortress"];

    // Landscape / Beings / Creatures
    // string[] public worldLusellasLandscapeBeingsCreatures = ["Tazevris Zebras","U7115 Star Sunrise","Vestigilis Nebula","Iriia Illuminated Wanderers","Agestis Light Sharks"];

    // Currency / Assets
    // string[] public worldLusellasCurrencyAssets = ["#978BC4 Coins x 62398","0.67786766 #E8BF8B","8746 #E7D27C","Endratis Tokens x 890000","Rialis Gateway Key"];

    // Transportation
    // string[] public worldLusellasTransportation = ["Mogrid Fuel Bus","Vena Lunar Shuttle","Patellic Fighter Ship","EAR Probe","Sea of Tell Ferry"];

    // Intergalactic Backpack
    // string[] public worldLusellasIntergalacticBackpack = ["U7115 Star Solar Battery Pack","#ED6572 Lipstick","Itaris Nebula Highschool Hoodie Size XL (Stolen)","Dr. E. Kemlin Ultra Smile Dentistry Business Card","Shimin Soy Sauce Packet (Less Sodium)"];


    // WORLD: TH47R23Y

    // Allies
    // string[] public worldTH47R23YAllies = ["Defected Xabril Scientist","Kentafi Soceress","Segaues Tyuli (Time Alliance Captain)","Vegerathi Tracker","E49012 (Escaped Parallel Time Prisoner)"];

    // Nemeses
    // string[] public worldTH47R23YNemeses = ["Parallel Time Creator","Zendis Dimensional Thief","Mubaton Bandit","Xabril Hour Reducer","Xabril Minute Reducer"];

    // Damage / Intoxication
    // string[] public worldTH47R23YDamageIntoxication = ["Hour Reduction Attack","Minute Reduction Attack","Millisecond Reduction Attack","Parallel Time Entrapment","Mubaton Zikeris Blade Damage"];

    // Weapons / Communication
    // string[] public worldTH47R23YWeaponsCommunication = ["Istenium Perma-Clock","Gemanis Blast","Covium Time Darts","Tatine Dimension Traversing Liquid","Engulfment Gun (Microscopic Black Hole Simulator)"];

    // Shields / Protection
    // string[] public worldTH47R23YShieldsProtection = ["Dessa Time Decay Warning Suit","Rium Space Isolation Room","Hafnium Blades","Hafnium Thread Suit","Jekanda Time Consumption Dark Shield"];

    // Surrounding Space / Bases
    // string[] public worldTH47R23YSurroundingSpaceBases = ["TYIUNFLK (moon)","U89FJAB (nebula)","23489JF (comet)","98JBJK (blackhole)","Xabril Inter-dimensional Re-entry Portals"];

    // Landscape / Beings / Creatures
    // string[] public worldTH47R23YLandscapeBeingsCreatures = ["Infinity Horses","Millisecond Decap Tulips","Waterfall Guards of Herasis","Atatine Mountains","Zophresis (Universal Clock Guardians)"];

    // Currency / Assets
    // string[] public worldTH47R23YCurrencyAssets = ["634284 Ubua Gems","Zophresis Micro Reversal Clocks x 19","Memory Stones of Inxatis x 6","Inxatis Shovel","79.45 Enci"];

    // Transportation
    // string[] public worldTH47R23YTransportation = ["Thorium Blade Ship","Angress Blast Capsule","Messason Agerin Sea Cargo Ship","TYIUNFLK Research Vessel","Vegerathi Evader"];

    // Intergalactic Backpack
    // string[] public worldTH47R23YIntergalacticBackpack = ["Two Passport Photos","3/4 Full U89FJAB Nebula Hotel Shampoo and Conditioner","Herasis Waterfalls Keychain","Introduction to Quantum Mechanics","Love Is A Chance In Time Diner Takeout Menu"];


    // WORLD: Diphadisan

    // Allies
    // string[] public worldDiphadisanAllies = ["Angelvalis 412 (Warrior)","_______t (Android robot)","Enjave Orabin","Jomre Orbit Guide","Ovesis Guard"];

    // Nemeses
    // string[] public worldDiphadisanNemeses = ["Ettra Lord","Ettra Queen","Flying Ettra Fire Releaser","Havunka Soldiers","Jomlin Body Substitution Probe"];

    // Damage / Intoxication
    // string[] public worldDiphadisanDamageIntoxication = ["Bissaevis Monoxide","Antril Gravity Decreaser","09456t Star Flares","Hesk Fatigue Gas","Mercury River Flood"];

    // Weapons / Communication
    // string[] public worldDiphadisanWeaponsCommunication = ["Thall Dagger","Modva Nebula Signaller","Thrasis Exploder","Vratta Chain","Tremkin Arrows"];

    // Shields / Protection
    // string[] public worldDiphadisanShieldsProtection = ["Juesils Jacket","Emntra Ice Shield","Emntra Ice Capsule","Messis Explosive Glue","Agelis Nails"];

    // Surrounding Space / Bases
    // string[] public worldDiphadisanSurroundingSpaceBases = ["F442 Star Trail","EF4EF Moon of Equasis","Venja 10 (Blackhole)","Anvagon 43 Nebula","Bessilas Comet"];

    // Landscape / Beings / Creatures
    // string[] public worldDiphadisanLandscapeBeingsCreatures = ["Algeninian Winds","Burning Sea of Merres","Tangril Fire Trenches","Mosaka Cliffs","Cybernetic Moose of Veris"];

    // Currency / Assets
    // string[] public worldDiphadisanCurrencyAssets = ["Tomril Ounces","Kajella x 457","Tiva Bags x 6790","Belsim Water","Stream of Andra Capsules"];

    // Transportation
    // string[] public worldDiphadisanTransportation = ["Ettra Fire Navigator","Varis Glacial Capsule","Metris Valley Darkness Evader","Igalis Hover Ship (Stolen)","Emntra Ice Horse"];

    // Intergalactic Backpack
    // string[] public worldDiphadisanIntergalacticBackpack = ["Metra Hoodie Price Tag","Somla Cake Factory Take-out Receipt","Standup on Saturn : A Comedic Autobiography","Hand-knit Lydium Cloth Scarf","Planet 67 Starbright Bubble Gum"];


    // WORLD: Grianfar

    // Allies
    // string[] public worldGrianfarAllies = ["Merresis Copywriter","Canvil Educator (Escaped)","Fatigued Berris Bird","Marri Sentient Orb","Mentra Cat"];

    // Nemeses
    // string[] public worldGrianfarNemeses = ["Henka Slicer","Tanni Crusher","Tereffi Glue Being","Mokka Grinder Bot","Grianfar Sand Crusher"];

    // Damage / Intoxication
    // string[] public worldGrianfarDamageIntoxication = ["Iratis Illusionary Ink Spray","Tivi Strobe","Wontra Divider Blasts","Abvra Disorientation Blasts","Enmin Pit Consumption Damage"];

    // Weapons / Communication
    // string[] public worldGrianfarWeaponsCommunication = ["Fifth Dimensional Paper Folds","Warp Propulsion Billboards","Konkillin Neon Blasters","Space Wall Scratch Pad","Micron Nitrogen Dice"];

    // Shields / Protection
    // string[] public worldGrianfarShieldsProtection = ["Wulafi Buggle Suit","Mossa Hall of Mirrors","janvelin retraction field","Adium Cancellation Gun","Menville Magnification Ball"];

    // Surrounding Space / Bases
    // string[] public worldGrianfarSurroundingSpaceBases = ["Ankora 72 E","Mentra Cat Resort","Canvil Star Alliance Asteroid Cluster","Mekra Gravity Presses","Xija 0_____"];

    // Landscape / Beings / Creatures
    // string[] public worldGrianfarLandscapeBeingsCreatures = ["Awi Light Slurper","Megu Yellers","Paper Trees of Tivi","Limi Billboard City","Lanthanamisi Dogs"];

    // Currency / Assets
    // string[] public worldGrianfarCurrencyAssets = [".000675 Tu","7900 Imeki","Tine Wind Grounders","Glasses of Fandoki (Stolen)","Megarin Stone Grinder"];

    // Transportation
    // string[] public worldGrianfarTransportation = ["Velshin Van","Canvil Billboard Installer (Stolen)","704 Cascadian Land Patroller","Tellrium City Board","Limi Light Orb"];

    // Intergalactic Backpack
    // string[] public worldGrianfarIntergalacticBackpack = ["UYT Moon Platinum Rings","Wesva Beach Sand Shell","Mentra Cat Resort Hang In There Kitten Keychain","Hairbrush","Grianfar Debit Card (Stolen)"];


    // WORLD: Kitpalasis

    // Allies
    // string[] public worldKitpalasisAllies = ["Kiptalian Worker 4200","Kiptalian Worker 5200","Moltravrian Ship Yard Scientist","Vetra Medakin","Danissi Songstress"];

    // Nemeses
    // string[] public worldKitpalasisNemeses = ["Fid Midiaris","Tanis Ship Builders","Estranged Melsovian Princess","Giant Eska Bulls","Wateris Vitana"];

    // Damage / Intoxication
    // string[] public worldKitpalasisDamageIntoxication = ["Temsis Attack","Ulgeni Fumes","Nonne Rope Burns","Riuum Fatigue","Tona Repulsion"];

    // Weapons / Communication
    // string[] public worldKitpalasisWeaponsCommunication = ["Scandium Blade","Nii Metal Grater","Message Parachute","Killiamis Pager","Tanis Moon Rotary Dimensional Dialer"];

    // Shields / Protection
    // string[] public worldKitpalasisShieldsProtection = ["Mask of Yllium","Bidi Body Shield","Cut Reversion Liquid","Tekra Blast Shield","Terbi Force Blast Anchor"];

    // Surrounding Space / Bases
    // string[] public worldKitpalasisSurroundingSpaceBases = ["MegaTUJ2 (blackhole)","Mega9Ux2 (blackhole)","MegaEErA (blackhole)","Galactic Steel Mills of Elmoin","Melsovian Reconnaissance Base"];

    // Landscape / Beings / Creatures
    // string[] public worldKitpalasisLandscapeBeingsCreatures = ["Titanium Sheep","Copper Triangle Fields","Ship Voyage Emulator (being)","Carbon Hills of Mudon","Telluriam Sea"];

    // Currency / Assets
    // string[] public worldKitpalasisCurrencyAssets = ["4 Gemarin","9,000,000,000,000 iii","4.6 kilograms Thallium","Jenvaril Eye Protector","14 Iridacii"];

    // Transportation
    // string[] public worldKitpalasisTransportation = ["14 Iridacii","Thallium Propeller Boat","Anriva Ground Tank","Betri Carbon Shoveller","Hydrogen Moon Evacuator"];

    // Intergalactic Backpack
    // string[] public worldKitpalasisIntergalacticBackpack = ["Mudon Brand Sharpie","Melsovian Metal Glimmer Lip Gloss","Solar Flare Sunglasses","Nonne Rope Particulate Allergy Spray","Real Quobitrons of Kitpalasis Season 12 Digital Pass"];


    // WORLD: Enrasilavis

    // Allies
    // string[] public worldEnrasilavisAllies = ["Tenna Warrior","Tenna Guide","Akena Muse","Varis Space Bandit","Joano Telvisrin (Galactic Lord)"];

    // Nemeses
    // string[] public worldEnrasilavisNemeses = ["Mestik Varis","Anachrite Killer","Demantic Hound","Sanverin Lava Spewer","Emattril Bats"];

    // Damage / Intoxication
    // string[] public worldEnrasilavisDamageIntoxication = ["Emattril Fang Bites","Demantic Tears","Javelin Distortion Echo","Menva Sand Drowning","Falling Tesis Fluid Burns"];

    // Weapons / Communication
    // string[] public worldEnrasilavisWeaponsCommunication = ["Genffa Magnets","Yusaris Inter-planetary Line","Seffla Convoluting Attack Vine","Dionaya Attack Plant","Earthquake Droplet of Medesis"];

    // Shields / Protection
    // string[] public worldEnrasilavisShieldsProtection = ["Ebvakalis Reversal Serum","Takosis Expelling Rain","Modrem Titanium Vest","essi healing soil","multra healing rake"];

    // Surrounding Space / Bases
    // string[] public worldEnrasilavisSurroundingSpaceBases = ["Enkatron Moon AAAA","Enkatron Moon AAAAA","Anachrite Landing Base","Empty Emattril Wolf Caves (Enkatron Moon AAAAAA)","Sovenna Spaceship Fluid Station"];

    // Landscape / Beings / Creatures
    // string[] public worldEnrasilavisLandscapeBeingsCreatures = ["Trees of Affera","Anjgan Grass","Emalla Herder","Mottra Goats","Envvu Cheetah Racers"];

    // Currency / Assets
    // string[] public worldEnrasilavisCurrencyAssets = ["467.89999 Tankis","Sifted Delphis Dirt x 89","Mektra Tarps x 14","2600 Centra","3.4 Welini"];

    // Transportation
    // string[] public worldEnrasilavisTransportation = ["Tenna Plough","Tenna Land Traverser","Agelin Sand Shoes","Muskadon Sky Hook","Ikandro Elevation Glider"];

    // Intergalactic Backpack
    // string[] public worldEnrasilavisIntergalacticBackpack = ["West Takosis Moon Brand Potato Chips","Emattril Energy Bar (gluten free)","Enkatron Office League Soccer Ball","Ganro Farms Glow Sticks (six pack)","Gravity Adjusted Sunflower Seeds"];


    // WORLD: 84RT74

    // Allies
    // string[] public world84RT74Allies = ["Trikaes (Belthasian Prince)","Metra (Belthasian Princess)","Rantika (Escaped Metron Slave)","Thempu (Zikta Warrior)","Muda (Catespian General)"];

    // Nemeses
    // string[] public world84RT74Nemeses = ["1E07DB63EF44 (Numbatron King)","4FFB5DDD04BE (Numbatron Queen)","54716776727B (Numbatron Guard)","5C995F7A840D (Numbatron Guard)","Vika (Numabtron Spy)"];

    // Damage / Intoxication
    // string[] public world84RT74DamageIntoxication = ["Espis Blade Jab","Selpha Water Burn","Brotta Damaging Cut","Vii Thunder Burn","Tesamika Fatigue Mist"];

    // Weapons / Communication
    // string[] public world84RT74WeaponsCommunication = ["Phetro Ray","Impaka Collision Blade","Visimo Phaser","Tenvis Claw","3ii Numbatron Relay Box"];

    // Shields / Protection
    // string[] public world84RT74ShieldsProtection = ["Green Antiak Cloak","Reflective Taan","Granite Dust Shield","A44 Weight Boots","Mussa Light Bridge Enforcer"];

    // Surrounding Space / Bases
    // string[] public world84RT74SurroundingSpaceBases = ["Vuslaron Golden Nebula","Moon Terrasis 41","Moon Anadiny 78","Numbatron Battle Base","Akelan Dwarf Star"];

    // Landscape / Beings / Creatures
    // string[] public world84RT74LandscapeBeingsCreatures = ["Temusason Aqua Grass","Lenndah Hills","Velveron Bison","Kitanis Mauler Beasts","Jevleresis Space Bats"];

    // Currency / Assets
    // string[] public world84RT74CurrencyAssets = ["256 Ultriia","1400 Miniia","167 Nubatron Semas Stones","89 Selfina Amulets","Jikila Ayelia Cloth"];

    // Transportation
    // string[] public world84RT74Transportation = ["Velmos Shuttle","Numbatron Stellar Craft","Numbatron Mesatil Launcher","Ravesin Basin Crawler","Night Flight Trasik Plane"];

    // Intergalactic Backpack
    // string[] public world84RT74IntergalacticBackpack = ["Burnt Velceron Tacos","Numbatron Discount Granola","House Of A Thousand Numbatron Daggers","Zavkre Projection Movie Capsule","Akelan Everburn Matches"];


    // WORLD: Niaselki

    // Allies
    // string[] public worldNiaselkiAllies = ["Moonatis Originating Scientist","Escaped Moonatis Farmer","Iagiti Sogora","Niobati Ajawero","Alshevian Husky"];

    // Nemeses
    // string[] public worldNiaselkiNemeses = ["Moonatis-Addicted Thief","Plant Hoarder","Konfari Guards","Megaris Vampire Whale","Yirialis Endare (Konfari Queen)"];

    // Damage / Intoxication
    // string[] public worldNiaselkiDamageIntoxication = ["Frost Damage","Congelation Ice Entrapment","Wind Storm Push","Ice Tesseract Maze Entrapment","Wata Forest Falling Tree Damage"];

    // Weapons / Communication
    // string[] public worldNiaselkiWeaponsCommunication = ["Amvaris Dimensional Javelin","Technatium Radioactive Chainsaw","Axe of Oviuum","Curri Blast Horn","Thorika Sonar Whistle"];

    // Shields / Protection
    // string[] public worldNiaselkiShieldsProtection = ["Fersope Heat Jacket","Sheet Ice Reconstructor","Ekraki Avalanche Warning Bird","Ressivi Blask Shield (Stolen)","Micro-nuclear Heating Capsule"];

    // Surrounding Space / Bases
    // string[] public worldNiaselkiSurroundingSpaceBases = ["900E Quasar","Ytttt6 (blackhole)","ETR47 (white dwarf)","Heater Waters of Wera (Moon Jaellis S)","Konfari Attack Formation Orbital Sphere"];

    // Landscape / Beings / Creatures
    // string[] public worldNiaselkiLandscapeBeingsCreatures = ["Ilikia Ice Fields","Ommja Mammoth","Vimmasouras","Tavuru Glacial Princess","Caves of Xiiraki"];

    // Currency / Assets
    // string[] public worldNiaselkiCurrencyAssets = ["78.5 Dranisi","20 Fettra Climbing Nails","Eijja Bartering Coins x 900","Modu Evja Gas Heater","Six-Hour Frost Storm Off-Planet Pass x 12"];

    // Transportation
    // string[] public worldNiaselkiTransportation = ["Atteris Snowmobile","Tra Laser Blast Valley Skaters","Envil Ice Destroyer Ship","Ice Cave Crawler","Low Hover Messaviactus Ship"];

    // Intergalactic Backpack
    // string[] public worldNiaselkiIntergalacticBackpack = ["MukaWuka Sushi Gift Card (600 Dransini)","Alshevian Husky Dental Treats","Wera Karis District Spa Locker Key","Moonatis Euphoria Capsule Lab Test Results","Xiiraki Didn't Consume Me! (Cave Exit Gift Shop T-Shirt)"];


    // WORLD: Gnikase

    // Allies
    // string[] public worldGnikaseAllies = ["Jemra Muratra","Vesvin Cleaner","Reprogrammed Metta Robot A","Reprogrammed Metta Robot B","Huventian Bay Door Operator"];

    // Nemeses
    // string[] public worldGnikaseNemeses = ["Morlar Lord","Morlar Lord Assassins","Inva Oil Serpents","Mechaniod Steel Destroyers","Missian Parafin Goblins"];

    // Damage / Intoxication
    // string[] public worldGnikaseDamageIntoxication = ["Ship Rust","Mittric Sand Grinding","Avesis Exploding Mines","Trel Oil Capacity Reducer","Entanglement Fence of Measis"];

    // Weapons / Communication
    // string[] public worldGnikaseWeaponsCommunication = ["Vanadiam Wrench","Ttri Propane Ignitiion Blaster","Iku Erbium Disk Launcher","Mentrollis Subsound Dialer","Avalli Sound Mist"];

    // Shields / Protection
    // string[] public worldGnikaseShieldsProtection = ["Thoriki Batle Wrap","Molrar Lord Assasin Battle Suit (Stolen)","Flero Escape Fluid","Density Reversal Blast","Deblirium Space Shield"];

    // Surrounding Space / Bases
    // string[] public worldGnikaseSurroundingSpaceBases = ["Lluri Landing Junction","Meska Moon A76","Meska Moon 9I","Velerisian Cluster Dust","Morlar Lord Assassin Retreat Base"];

    // Landscape / Beings / Creatures
    // string[] public worldGnikaseLandscapeBeingsCreatures = ["Abandoned Kelium Hills","Wandering Aluminium Grazers","Desolate Roads of Iri","Meki Transparency Grass","Humanoid Vrass Cargo Collectors"];

    // Currency / Assets
    // string[] public worldGnikaseCurrencyAssets = ["999.03456 Esi","22,009,023 Trika","Copper Monra x 50","Silver Monra x 80","Soap of Jupi"];

    // Transportation
    // string[] public worldGnikaseTransportation = ["Makri Tractor","Vrass Cargo Loader (modified)","Jemli Car","Meska Moon Runners","Avesis Transportation Pass"];

    // Intergalactic Backpack
    // string[] public worldGnikaseIntergalacticBackpack = ["1-996-Moon-Junk 20% Coupon","Yosta Nebula Dust Resistant Calculator","Velerisian Driver's License Renewal Form","Leaking Deblirium Hotel and Spa Pen","Ripped Bag Moschiu Brand Gummy Worms"];


    // WORLD: 111111111111R

    // Allies
    // string[] public world111111111111RAllies = ["11R Leffa Preserver (Bandit)","Feltra Oillands Robot","Guella (Progeny of 10111R1)","Rtik (Daughter of 1118000R)","1RR1RR Legion Defectors"];

    // Nemeses
    // string[] public world111111111111RNemeses = ["1RR1RR Legion","Liquid Poi Eradicators","Falkarian Battle Machine","Epkelis Hyposis Scavengers","1111RRRR Digital Tekelizers"];

    // Damage / Intoxication
    // string[] public world111111111111RDamageIntoxication = ["RR Byte Corruption","11111 Obfuscation Lasers","Etril Amalgamation","Decamen Eradication","Binary Memory Corruption"];

    // Weapons / Communication
    // string[] public world111111111111RWeaponsCommunication = ["111111111 Blobification Gun","Kandilla Radio","R1 Segmented Quasar Portal","R5t76 Signal qWERTY Box","Nano Quantum Fabric Blade"];

    // Shields / Protection
    // string[] public world111111111111RShieldsProtection = ["RRRRRR1 Disposable Shield","RRRRRR2 Multi-Use Quasar Arm Brace","Millisecond Reversal Blast","Feltina Cave Drop Absorption Suit","Darkmatter Explosive USB"];

    // Surrounding Space / Bases
    // string[] public world111111111111RSurroundingSpaceBases = ["Poi Moon-Gravity Army Base","T5E Sona (Star)","4Q2OIA (blackhole)","The Oilands of Mesuadon","Legion Defectors Lagrange Point"];

    // Landscape / Beings / Creatures
    // string[] public world111111111111RLandscapeBeingsCreatures = ["Fields of Binary Grass","Nanocore Mountains","Helpasidis Tree Eater","11111111R11 Helium Wind Dwellers","Musoko Number Merchants"];

    // Currency / Assets
    // string[] public world111111111111RCurrencyAssets = ["1256892 Musoka","500 hekagrams Binary Diamond Shaving","Semi Infinite Memory Array x 46","Aragon CPU Voucher","Zencilla Passage Coins X 10"];

    // Transportation
    // string[] public world111111111111RTransportation = ["Kentris Shipping Crate","11111R1 Gravitational Loop","Vemula Quantum Bus Depot","1118000R Oil Absorbent Shuttle","Hefshin Moon Magnet Glider"];

    // Intergalactic Backpack
    // string[] public world111111111111RIntergalacticBackpack = ["111111111111R Vintage Floppy Disk No. 274","Binary Depot 6000 Musoka Gift Card","Happy Sunshine Art Co. Sketch Pad","Velsivis Sulfur Rain Umbrella","Nebrakik Exchange 24/7 Reusable Mug"];


    // WORLD: Earth

    // Allies
    // string[] public worldEarthAllies = ["Milton Andrews","Janfe Afwar","Claire Orsales","Ex-Military Gas Station Attendant","Pharmacist"];

    // Nemeses
    // string[] public worldEarthNemeses = ["Mutating Helratians","Trakattis Cybernetic Land Hunters","System Overriden Car Assembly Robots","Belcine Fire-Breathing Destroyer","Nekirisa Scavenging Acid-Spiting Vultures"];

    // Damage / Intoxication
    // string[] public worldEarthDamageIntoxication = ["Helration Mutation Bite","Land Hunter Attack Scratches","Assembly Robot Vehicle Damage","Belcine Icineration","Nekirisa Acid Burns"];

    // Weapons / Communication
    // string[] public worldEarthWeaponsCommunication = ["Axe","Hunting Knife","Helratian Axis Blade (Stolen)","Google Pixel 3 Not Pink","Nevalis Blast Capsules (Stolen)"];

    // Shields / Protection
    // string[] public worldEarthShieldsProtection = ["Kevlar Bulletproof Vest","Helratian Tactical Suit (Stolen)","Blast Separated Car Door","Frequency Modified Pull Pin Alarm","Art Exhibit Portable Laser Alarm"];

    // Surrounding Space / Bases
    // string[] public worldEarthSurroundingSpaceBases = ["NASA Moon Colony 867B","Helratian Dimensional Travel Base EEE4","Unlissa Comet","International Space Bridge Dock 49A","SpaceX Synthetic Atmospheric Earth Shield"];

    // Landscape / Beings / Creatures
    // string[] public worldEarthLandscapeBeingsCreatures = ["Sunken California Coast Diving Cliffs","Nile River Riverbed Dance Club","Ankis Brand Mechanical Wild Tiger","Trapsis Foods Genetic Burger Cow","Amazon Rainforest Concrete Overlay Simulation"];

    // Currency / Assets
    // string[] public worldEarthCurrencyAssets = ["0.23 Bitcoin","4 Ethereum","$517.30","812 Tesla Inc. Shares","12 Attica Greece Silver Tetradrachm Coins"];

    // Transportation
    // string[] public worldEarthTransportation = ["1976 Buick Electra Limited","Helratian Photon Solo Avenger (Stolen)","2000 Hummer H1 Limited Edition","1977 Fiat 124","3029 Tesla Model S SpaceX Galactic Thrust Edition"];

    // Intergalactic Backpack
    // string[] public worldEarthIntergalacticBackpack = ["CHEETOS Puffs FLAMIN HOT Cheese Flavored","Duct Tape","Apple Macbook Pro","The Incredible Hulk and Wolverine No. 1 October 1986","Pokemon Card Appraisal Complaint Form"];


    // WORLD: Mars

    // Allies
    // string[] public worldMarsAllies = ["Solar Technician","Microbe Scientist","Escaped Helratian Prisoner","Europa Mission Pilot","Dust Scavengers"];

    // Nemeses
    // string[] public worldMarsNemeses = ["Laser-Eyed Mutating Helratians","Helratian Burrowing Attack Bots","Mutant Electrolysis Technician","Anti-Colonization Anthropologist","Mudu World Destroyer"];

    // Damage / Intoxication
    // string[] public worldMarsDamageIntoxication = ["Skeletal Deterioration","Muscle Atrophy","Diminished Eyesight","Cosmic Ray Nerve Damage","Cosmic Ray DNA Alteration"];

    // Weapons / Communication
    // string[] public worldMarsWeaponsCommunication = ["Helration Low-Gravity Blaster (Stolen)","NASA JPL Laser (Reappropriated) ","SpaceX Mars Mission Digital Walkie","Havanix Energy Compressor (Stolen)","Escape Pod Flares"];

    // Shields / Protection
    // string[] public worldMarsShieldsProtection = ["SpaceX Mars Cosmic Ray Shield Suit","NASA JPL Anti-Radiation Exploration Pod","Gravity Reversal Boots","Helration Deflector Arm Sheaths (Stolen)","Mars Exploration Society Antimicrobial Serum"];

    // Surrounding Space / Bases
    // string[] public worldMarsSurroundingSpaceBases = ["Mugladon Helratian Vortex Traverser","Europa","Enceladus","SpaceX Mars Orbit Station 12","International Mars Orbital Jump Base"];

    // Landscape / Beings / Creatures
    // string[] public worldMarsLandscapeBeingsCreatures = ["Kentra Industries Electrolysis Fields","Section 78 Area 42 Oxygen Chambers","Section 19 Area 56 Oxygen Chambers","Water Extraction Algae","Dekra W566 Planetary Dust Storm"];

    // Currency / Assets
    // string[] public worldMarsCurrencyAssets = ["491 Mars Coin","Okratis Go-Ship Personal Oxygen Canister","14.7 liter water vouchers","Lithium Battery Pack x 5","3400 Solar Hour Credits"];

    // Transportation
    // string[] public worldMarsTransportation = ["Microbial Sample Rover (Stolen)","Enceladus Exploration Ship","Magnetic Hover Vehicle","Intra-colony Capsule System","NASA Ignition Booster Red Suit"];

    // Intergalactic Backpack
    // string[] public worldMarsIntergalacticBackpack = ["Mars Mars Bar","Hydroponic Lettuce Wrap","Earth 3073 Collectable Calendar","Solar Compass","Planet Red Mini Golf and Bowling Loyalty Card"];


    // WORLD: AlakosVortex

    // Allies
    // string[] public worldAlakosVortexAllies = ["Forsithina (Thermal Energy Manifestation)","Netrila (Lost Star Jumper)","The Metruliae","Vortex Gas And Lodging Attendant","Miuvillian Senator"];

    // Nemeses
    // string[] public worldAlakosVortexNemeses = ["Dark Matter Cyclops","Dimensional Engulfment Slitherine","Tesseract Spider","Shifting Nebula Scorpion","Velocity Hyperplane Ghost"];

    // Damage / Intoxication
    // string[] public worldAlakosVortexDamageIntoxication = ["Essinga Passageway Shrapnel","Hyperspeed Light Burns","Mong4A Asteroid Collisions","Tamrisian Brake Dust","Ganle Delusion Fluid"];

    // Weapons / Communication
    // string[] public worldAlakosVortexWeaponsCommunication = ["Carbon Multi-Vector Cluster Bomb","Felsin Time Whistle","Veklii Ice Blade","Tentrii Signal Drum","Miuvillian Sonar Pager"];

    // Shields / Protection
    // string[] public worldAlakosVortexShieldsProtection = ["Dynamic Gamma Ray Disperser","Kelvin Suit","Inwa Compression Capsule","Quantum Gravity Evasion String","One-dimensional Voice Compressor"];

    // Surrounding Space / Bases
    // string[] public worldAlakosVortexSurroundingSpaceBases = ["Ussah Meteor","Mentrilis Comet","754RTXVF (Comet)","Janla 1167K (Blackhole)","Chesitas Nebula"];

    // Landscape / Beings / Creatures
    // string[] public worldAlakosVortexLandscapeBeingsCreatures = ["Ultronakis Sound Worm","Metikasis Time Harvester","Shema Duality Dust","Petresis Warp Birds","Hungubria Chantillas"];

    // Currency / Assets
    // string[] public worldAlakosVortexCurrencyAssets = ["Thekesis Propsolsion Fluid","Takilis Emeralds x 42","Somesis Transport Pass","Horizontal Allegiance Evasion Star Maps","Asteroid 4132 Palladium Coins x 76"];

    // Transportation
    // string[] public worldAlakosVortexTransportation = ["Helratian Vortex Navigator (Stolen)","Metruliae Thrust Fighter","Vertex Gas Inter-Station Voyager","Helu Beam Sand Nebula Blaster","Tamrisian Speed Destroyer"];

    // Intergalactic Backpack
    // string[] public worldAlakosVortexIntergalacticBackpack = ["Convolution Mist","Jakathintik Gyroscope","Four Dimensional Flashlight","Dust Nebula Windbreaker","Antimatter Safety Flare"];


    constructor() ERC721("Intergalactic Backpack Pack One", "PACKONE") Ownable() {}

    // Mint functionality

    function mint(uint256 _count) public payable {
        uint256 s = totalSupply();
        require(_count > 0 && _count < R + 1, "> max single buy");
        require(s + _count < M + 1, "> tokens available");
        require(msg.value >= y.mul(_count), "fix ETH sent");

        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, s + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getPrice() public view returns (uint256){
        return y;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Random function

    function z(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Helratian mutation percentage

    // function tA(uint256 tokenId) private view returns (string memory) {

    //     string[100] memory p = ["1%", "2%", "3%", "4%", "5%", "6%", "7%", "8%", "9%", "10%", "11%", "12%", "13%", "14%", "15%", "16%", "17%", "18%", "19%", "20%", "21%", "22%", "23%", "24%", "25%", "26%", "27%", "28%", "29%", "30%", "31%", "32%", "33%", "34%", "35%", "36%", "37%", "38%", "39%", "40%", "41%", "42%", "43%", "44%", "45%", "46%", "47%", "48%", "49%", "50%", "51%", "52%", "53%", "54%", "55%", "56%", "57%", "58%", "59%", "60%", "61%", "62%", "63%", "64%", "65%", "66%", "67%", "68%", "69%", "70%", "71%", "72%", "73%", "74%", "75%", "76%", "77%", "78%", "79%", "80%", "81%", "82%", "83%", "84%", "85%", "86%", "87%", "88%", "89%", "90%", "91%", "92%", "93%", "94%", "95%", "96%", "97%", "98%", "99%", "100%"];

    //     uint l = p.length;
    //     uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //     uint256 i = v % l--;
    //     string memory r = p[i];
    //     string memory j;
    //     j = string(abi.encodePacked(r, " Helratian"));
    //     return j;

    // }

    // Entranika gems retrieved

    // function tB(uint256 tokenId) private view returns (string memory) {

    //     string[12] memory g = ["1","2","3","4","5","6","7","8","9","10","11","12"];

    //     uint l = g.length;
    //     uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //     uint256 i = v % l--;
    //     string memory r = g[i];
    //     string memory j;
    //     j = string(abi.encodePacked("Entranika Gems: ", r));
    //     return j;

    // }

    // Lightyears travelled

    // function tC(uint256 tokenId) private view returns (string memory) {

    //     uint256 m = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    //     uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //     uint256 n = v % m;
    //     uint256 t = n % 9461000000000;
    //     string memory r = toString(t);
    //     string memory j;
    //     j = string(abi.encodePacked(r, " light years"));
    //     return j;

    // }

    // // Shuffle intergalactic backpacks

    // function sA(uint256 tokenId) internal view returns (string[75] memory) {

    //   string[75] memory r;
    //   string[75] memory s = ["The Dust Times Weekly Sunday Magazine","Juibatik Science Center Poker Cards","www4vas Boba House Loyalty Card","Jinfara Moon Brand Sugarfree Cough Drops","Snasis Leaf Anti-Allergy Tablets","Internebular University Never-Dry Hi-Liter","One Uff Performance Quantum Quick Dry Sock","Tronitii Brand Heffa Bean Snacks","Exabyte Conversation Memory Headphones","Juicy Cosmic Ultra Mint Gum Wrapper","U7115 Star Solar Battery Pack","#ED6572 Lipstick","Itaris Nebula Highschool Hoodie Size XL (Stolen)","Dr. E. Kemlin Ultra Smile Dentistry Business Card","Shimin Soy Sauce Packet (Less Sodium)","Two Passport Photos","3/4 Full U89FJAB Nebula Hotel Shampoo and Conditioner","Herasis Waterfalls Keychain","Introduction to Quantum Mechanics","Love Is A Chance In Time Diner Takeout Menu","Metra Hoodie Price Tag","Somla Cake Factory Take-out Receipt","Standup on Saturn : A Comedic Autobiography","Hand-knit Lydium Cloth Scarf","Planet 67 Starbright Bubble Gum","UYT Moon Platinum Rings","Wesva Beach Sand Shell","Mentra Cat Resort Hang In There Kitten Keychain","Hairbrush","Grianfar Debit Card (Stolen)","Mudon Brand Sharpie","Melsovian Metal Glimmer Lip Gloss","Solar Flare Sunglasses","Nonne Rope Particulate Allergy Spray","Real Quobitrons of Kitpalasis Season 12 Digital Pass","West Takosis Moon Brand Potato Chips","Emattril Energy Bar (gluten free)","Enkatron Office League Soccer Ball","Ganro Farms Glow Sticks (six pack)","Gravity Adjusted Sunflower Seeds","Burnt Velceron Tacos","Numbatron Discount Granola","House Of A Thousand Numbatron Daggers","Zavkre Projection Movie Capsule","Akelan Everburn Matches","MukaWuka Sushi Gift Card (600 Dransini)","Alshevian Husky Dental Treats","Wera Karis District Spa Locker Key","Moonatis Euphoria Capsule Lab Test Results","Xiiraki Didn't Consume Me! (Cave Exit Gift Shop T-Shirt)","1-996-Moon-Junk 20% Coupon","Yosta Nebula Dust Resistant Calculator","Velerisian Driver's License Renewal Form","Leaking Deblirium Hotel and Spa Pen","Ripped Bag Moschiu Brand Gummy Worms","111111111111R Vintage Floppy Disk No. 274","Binary Depot 6000 Musoka Gift Card","Happy Sunshine Art Co. Sketch Pad","Velsivis Sulfur Rain Umbrella","Nebrakik Exchange 24/7 Reusable Mug","CHEETOS Puffs FLAMIN HOT Cheese Flavored","Duct Tape","Apple Macbook Pro","The Incredible Hulk and Wolverine No. 1 October 1986","Pokemon Card Appraisal Complaint Form","Mars Mars Bar","Hydroponic Lettuce Wrap","Earth 3073 Collectable Calendar","Solar Compass","Planet Red Mini Golf and Bowling Loyalty Card","Convolution Mist","Jakathintik Gyroscope","Four Dimensional Flashlight","Dust Nebula Windbreaker","Antimatter Safety Flare"];

    //   uint l = s.length;
    //   uint i;
    //   string memory t;

    //   while (l > 0) {
    //       uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //       i = v % l--;
    //       t = s[l];
    //       s[l] = s[i];
    //       s[i] = t;
    //   }

    //   r = s;

    //   return r;

    // }

    // Shuffle allies

    function sB(uint256 tokenId) internal view returns (string[75] memory) {

      string[75] memory r;
      string[75] memory s = ["MakMak Jumper","wwrtdy sumbetrin","rrarra kashefi","mestia the burrower","oracle vansilla", "Kesif (Thamaran Prisoner)","Mulaka Avantaris (Thamarian Prisoner)","Rika 34724 (Escaped Thamarian Guard)","Sonkelis","Matrivi", "#FEEB99 (Lusellain Being)","#F8EDDC (Lusellain Being)","#EDC5E4 (Lusellain Being)","#EDBEC8 (Lusellain Being)","#FDDAE3 (Lusellain Being)", "Defected Xabril Scientist","Kentafi Soceress","Segaues Tyuli (Time Alliance Captain)","Vegerathi Tracker","E49012 (Escaped Parallel Time Prisoner)", "Angelvalis 412 (Warrior)","_______t (Android robot)","Enjave Orabin","Jomre Orbit Guide","Ovesis Guard", "Merresis Copywriter","Canvil Educator (Escaped)","Fatigued Berris Bird","Marri Sentient Orb","Mentra Cat", "Kiptalian Worker 4200","Kiptalian Worker 5200","Moltravrian Ship Yard Scientist","Vetra Medakin","Danissi Songstress", "Tenna Warrior","Tenna Guide","Akena Muse","Varis Space Bandit","Joano Telvisrin (Galactic Lord)", "Trikaes (Belthasian Prince)","Metra (Belthasian Princess)","Rantika (Escaped Metron Slave)","Thempu (Zikta Warrior)","Muda (Catespian General)", "Moonatis Originating Scientist","Escaped Moonatis Farmer","Iagiti Sogora","Niobati Ajawero","Alshevian Husky", "Jemra Muratra","Vesvin Cleaner","Reprogrammed Metta Robot A","Reprogrammed Metta Robot B","Huventian Bay Door Operator", "11R Leffa Preserver (Bandit)","Feltra Oillands Robot","Guella (Progeny of 10111R1)","Rtik (Daughter of 1118000R)","1RR1RR Legion Defectors", "Milton Andrews","Janfe Afwar","Claire Orsales","Ex-Military Gas Station Attendant","Pharmacist", "Solar Technician","Microbe Scientist","Escaped Helratian Prisoner","Europa Mission Pilot","Dust Scavengers", "Forsithina (Thermal Energy Manifestation)","Netrila (Lost Star Jumper)","The Metruliae","Vortex Gas And Lodging Attendant","Miuvillian Senator"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      return r;

    }

    // Shuffle nemeses

    function sC(uint256 tokenId) internal view returns (string[75] memory) {

      string[75] memory r;
      string[75] memory s = ["aragon tenvis lords","inkatheis MakMak killers","pattri mites","svanves mutila","wwwi895 Destroyer Gravity Caterpillars", "Thamaran Cognition Serpent","Aleros","Juvabis Destruction Beast","The Antakela","Rika Seba 84003 (Thamarian Leader)", "#E1C2D9 (Lusellain Being)","#AEA7D1 (Lusellain Being)","#B8B1C1 (Lusellain Being)","#C3A2BF (Lusellain Being)","#978BC4 (Lusellain Being)", "Parallel Time Creator","Zendis Dimensional Thief","Mubaton Bandit","Xabril Hour Reducer","Xabril Minute Reducer", "Ettra Lord","Ettra Queen","Flying Ettra Fire Releaser","Havunka Soldiers","Jomlin Body Substitution Probe", "Henka Slicer","Tanni Crusher","Tereffi Glue Being","Mokka Grinder Bot","Grianfar Sand Crusher", "Fid Midiaris","Tanis Ship Builders","Estranged Melsovian Princess","Giant Eska Bulls","Wateris Vitana", "Mestik Varis","Anachrite Killer","Demantic Hound","Sanverin Lava Spewer","Emattril Bats", "1E07DB63EF44 (Numbatron King)","4FFB5DDD04BE (Numbatron Queen)","54716776727B (Numbatron Guard)","5C995F7A840D (Numbatron Guard)","Vika (Numabtron Spy)", "Moonatis-Addicted Thief","Plant Hoarder","Konfari Guards","Megaris Vampire Whale","Yirialis Endare (Konfari Queen)", "Morlar Lord","Morlar Lord Assassins","Inva Oil Serpents","Mechaniod Steel Destroyers","Missian Parafin Goblins", "1RR1RR Legion","Liquid Poi Eradicators","Falkarian Battle Machine","Epkelis Hyposis Scavengers","1111RRRR Digital Tekelizers", "Mutating Helratians","Trakattis Cybernetic Land Hunters","System Overriden Car Assembly Robots","Belcine Fire-Breathing Destroyer","Nekirisa Scavenging Acid-Spiting Vultures", "Laser-Eyed Mutating Helratians","Helratian Burrowing Attack Bots","Mutant Electrolysis Technician","Anti-Colonization Anthropologist","Mudu World Destroyer", "Dark Matter Cyclops","Dimensional Engulfment Slitherine","Tesseract Spider","Shifting Nebula Scorpion","Velocity Hyperplane Ghost"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      return r;

    }

    // Shuffle damage intoxication

    function sD(uint256 tokenId) internal view returns (string[75] memory) {

      string[75] memory r;
      string[75] memory s = ["phesis dirt burial","ww783av rock collision","Snasis Leaf cuts","e8889 dust storm","q21i aluminum shard wind", "Menkra Heat Burns","Palladium Intoxication","Eviscerating Blade of Thekatis","Thamarian Illusionary Pollen","Centril Dust", "Lusela Color Deterioration Attack","Nvarisa Palette Transformation","Black and White Confinement","Vesin Gamma Blast","Gyroscopic Deterioration", "Hour Reduction Attack","Minute Reduction Attack","Millisecond Reduction Attack","Parallel Time Entrapment","Mubaton Zikeris Blade Damage", "Bissaevis Monoxide","Antril Gravity Decreaser","09456t Star Flares","Hesk Fatigue Gas","Mercury River Flood", "Iratis Illusionary Ink Spray","Tivi Strobe","Wontra Divider Blasts","Abvra Disorientation Blasts","Enmin Pit Consumption Damage", "Temsis Attack","Ulgeni Fumes","Nonne Rope Burns","Riuum Fatigue","Tona Repulsion", "Emattril Fang Bites","Demantic Tears","Javelin Distortion Echo","Menva Sand Drowning","Falling Tesis Fluid Burns", "Espis Blade Jab","Selpha Water Burn","Brotta Damaging Cut","Vii Thunder Burn","Tesamika Fatigue Mist", "Frost Damage","Congelation Ice Entrapment","Wind Storm Push","Ice Tesseract Maze Entrapment","Wata Forest Falling Tree Damage", "Ship Rust","Mittric Sand Grinding","Avesis Exploding Mines","Trel Oil Capacity Reducer","Entanglement Fence of Measis", "RR Byte Corruption","11111 Obfuscation Lasers","Etril Amalgamation","Decamen Eradication","Binary Memory Corruption", "Helration Mutation Bite","Land Hunter Attack Scratches","Assembly Robot Vehicle Damage","Belcine Icineration","Nekirisa Acid Burns", "Skeletal Deterioration","Muscle Atrophy","Diminished Eyesight","Cosmic Ray Nerve Damage","Cosmic Ray DNA Alteration", "Essinga Passageway Shrapnel","Hyperspeed Light Burns","Mong4A Asteroid Collisions","Tamrisian Brake Dust","Ganle Delusion Fluid"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      return r;

    }

    // Shuffle weapons communication

    // function sE(uint256 tokenId) internal view returns (string[75] memory) {

    //   string[75] memory r;
    //   string[75] memory s = ["ww509sen contraction rope","dimensional hypothesis axe","nebula dust chemtrail gun","Venchibu Model4T9 Galactic Dialer","vanesis thorn blade", "Menkra Heat Gun","Palladium Dagger","Woltron Dimensional Stone","Ando World Dialer","Metisa Cosmic Relay", "Jekka Palette","#F1C470 Blast","#FECBA5 Disorientation Orbs","#76CBF0 Drowning Blaster","#FFCADD Intoxicator", "Istenium Perma-Clock","Gemanis Blast","Covium Time Darts","Tatine Dimension Traversing Liquid","Engulfment Gun (Microscopic Black Hole Simulator)", "Thall Dagger","Modva Nebula Signaller","Thrasis Exploder","Vratta Chain","Tremkin Arrows", "Fifth Dimensional Paper Folds","Warp Propulsion Billboards","Konkillin Neon Blasters","Space Wall Scratch Pad","Micron Nitrogen Dice", "Scandium Blade","Nii Metal Grater","Message Parachute","Killiamis Pager","Tanis Moon Rotary Dimensional Dialer", "Genffa Magnets","Yusaris Inter-planetary Line","Seffla Convoluting Attack Vine","Dionaya Attack Plant","Earthquake Droplet of Medesis", "Phetro Ray","Impaka Collision Blade","Visimo Phaser","Tenvis Claw","3ii Numbatron Relay Box", "Amvaris Dimensional Javelin","Technatium Radioactive Chainsaw","Axe of Oviuum","Curri Blast Horn","Thorika Sonar Whistle", "Vanadiam Wrench","Ttri Propane Ignitiion Blaster","Iku Erbium Disk Launcher","Mentrollis Subsound Dialer","Avalli Sound Mist", "111111111 Blobification Gun","Kandilla Radio","R1 Segmented Quasar Portal","R5t76 Signal qWERTY Box","Nano Quantum Fabric Blade", "Axe","Hunting Knife","Helratian Axis Blade (Stolen)","Google Pixel 3 Not Pink","Nevalis Blast Capsules (Stolen)", "Helration Low-Gravity Blaster (Stolen)","NASA JPL Laser (Reappropriated) ","SpaceX Mars Mission Digital Walkie","Havanix Energy Compressor (Stolen)","Escape Pod Flares", "Carbon Multi-Vector Cluster Bomb","Felsin Time Whistle","Veklii Ice Blade","Tentrii Signal Drum","Miuvillian Sonar Pager"];

    //   uint l = s.length;
    //   uint i;
    //   string memory t;

    //   while (l > 0) {
    //       uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //       i = v % l--;
    //       t = s[l];
    //       s[l] = s[i];
    //       s[i] = t;
    //   }

    //   r = s;

    //   return r;

    // }

    // Shuffle shields protection

    // function sF(uint256 tokenId) internal view returns (string[75] memory) {

    //   string[75] memory r;
    //   string[75] memory s = ["wqwq7T569 MakMak military net","keshvin concurrency modulation shroud","aluminium wwi894t charge deflection suit","muskrate syrum","DEFINITIS ILLUSION LIGHT", "Cobalt Protection Suit","Artila Deflection Force","Festa Asteroid Blaster","Thamarian Energy Disperser","Ulla Darkmatter Suit", "#B9DFD4 Biogenetic Shield","#F7CDEC Photon Resistant Chamber","#D4C6F5 Deflection Blades","#FFF7D1 Trajectory Reversal Chamber","Radiuum Body Circle", "Dessa Time Decay Warning Suit","Rium Space Isolation Room","Hafnium Blades","Hafnium Thread Suit","Jekanda Time Consumption Dark Shield", "Juesils Jacket","Emntra Ice Shield","Emntra Ice Capsule","Messis Explosive Glue","Agelis Nails", "Wulafi Buggle Suit","Mossa Hall of Mirrors","janvelin retraction field","Adium Cancellation Gun","Menville Magnification Ball", "Mask of Yllium","Bidi Body Shield","Cut Reversion Liquid","Tekra Blast Shield","Terbi Force Blast Anchor", "Ebvakalis Reversal Serum","Takosis Expelling Rain","Modrem Titanium Vest","essi healing soil","multra healing rake", "Green Antiak Cloak","Reflective Taan","Granite Dust Shield","A44 Weight Boots","Mussa Light Bridge Enforcer", "Fersope Heat Jacket","Sheet Ice Reconstructor","Ekraki Avalanche Warning Bird","Ressivi Blask Shield (Stolen)","Micro-nuclear Heating Capsule", "Thoriki Batle Wrap","Molrar Lord Assasin Battle Suit (Stolen)","Flero Escape Fluid","Density Reversal Blast","Deblirium Space Shield", "RRRRRR1 Disposable Shield","RRRRRR2 Multi-Use Quasar Arm Brace","Millisecond Reversal Blast","Feltina Cave Drop Absorption Suit","Darkmatter Explosive USB", "Kevlar Bulletproof Vest","Helratian Tactical Suit (Stolen)","Blast Separated Car Door","Frequency Modified Pull Pin Alarm","Art Exhibit Portable Laser Alarm", "SpaceX Mars Cosmic Ray Shield Suit","NASA JPL Anti-Radiation Exploration Pod","Gravity Reversal Boots","Helration Deflector Arm Sheaths (Stolen)","Mars Exploration Society Antimicrobial Serum", "Dynamic Gamma Ray Disperser","Kelvin Suit","Inwa Compression Capsule","Quantum Gravity Evasion String","One-dimensional Voice Compressor"];

    //   uint l = s.length;
    //   uint i;
    //   string memory t;

    //   while (l > 0) {
    //       uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //       i = v % l--;
    //       t = s[l];
    //       s[l] = s[i];
    //       s[i] = t;
    //   }

    //   r = s;

    //   return r;

    // }

    // Shuffle surrounding space bases

    // function sG(uint256 tokenId) internal view returns (string[75] memory) {

    //   string[75] memory r;
    //   string[75] memory s = ["Jinfara Moon w4","vansilla extradition camp","MakMak asteroid","ww7984rhk blackhole","pattri space bile", "J56R (Moon of Mesaesis)","Tolla 4 (Thamarian Base)","Tolla 5 (Thamarian Base)","Hafra 26 (Moon of the Thamarian Senate)","Galla 9 (Meteor)", "Vurra Atmospheric Escape Stairs","#C9E9F5 Moon","#E1F5F3 Comet","Asterids of Angeris","Lessi Resistance Orbital Fortress", "TYIUNFLK (moon)","U89FJAB (nebula)","23489JF (comet)","98JBJK (blackhole)","Xabril Inter-dimensional Re-entry Portals", "F442 Star Trail","EF4EF Moon of Equasis","Venja 10 (Blackhole)","Anvagon 43 Nebula","Bessilas Comet", "Ankora 72 E","Mentra Cat Resort","Canvil Star Alliance Asteroid Cluster","Mekra Gravity Presses","Xija 0_____", "MegaTUJ2 (blackhole)","Mega9Ux2 (blackhole)","MegaEErA (blackhole)","Galactic Steel Mills of Elmoin","Melsovian Reconnaissance Base", "Enkatron Moon AAAA","Enkatron Moon AAAAA","Anachrite Landing Base","Empty Emattril Wolf Caves (Enkatron Moon AAAAAA)","Sovenna Spaceship Fluid Station", "Vuslaron Golden Nebula","Moon Terrasis 41","Moon Anadiny 78","Numbatron Battle Base","Akelan Dwarf Star", "900E Quasar","Ytttt6 (blackhole)","ETR47 (white dwarf)","Heater Waters of Wera (Moon Jaellis S)","Konfari Attack Formation Orbital Sphere", "Lluri Landing Junction","Meska Moon A76","Meska Moon 9I","Velerisian Cluster Dust","Morlar Lord Assassin Retreat Base", "Poi Moon-Gravity Army Base","T5E Sona (Star)","4Q2OIA (blackhole)","The Oilands of Mesuadon","Legion Defectors Lagrange Point", "NASA Moon Colony 867B","Helratian Dimensional Travel Base EEE4","Unlissa Comet","International Space Bridge Dock 49A","SpaceX Synthetic Atmospheric Earth Shield", "Mugladon Helratian Vortex Traverser","Europa","Enceladus","SpaceX Mars Orbit Station 12","International Mars Orbital Jump Base", "Ussah Meteor","Mentrilis Comet","754RTXVF (Comet)","Janla 1167K (Blackhole)","Chesitas Nebula"];

    //   uint l = s.length;
    //   uint i;
    //   string memory t;

    //   while (l > 0) {
    //       uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //       i = v % l--;
    //       t = s[l];
    //       s[l] = s[i];
    //       s[i] = t;
    //   }

    //   r = s;

    //   return r;

    // }

    // Shuffle landscape beings creatures

    // function sH(uint256 tokenId) internal view returns (string[75] memory) {

    //   string[75] memory r;
    //   string[75] memory s = ["www8CXa dirt fields","poliaki moss eaters","0009a moon dust debris","blue avakalon ice condors","wind consuming mukahs", "Wild Rutherian Drinkers","Tevita Hills","Rhenium Valley","Visionary of Effa (Being)","The Tronitii", "Tazevris Zebras","U7115 Star Sunrise","Vestigilis Nebula","Iriia Illuminated Wanderers","Agestis Light Sharks", "Infinity Horses","Millisecond Decap Tulips","Waterfall Guards of Herasis","Atatine Mountains","Zophresis (Universal Clock Guardians)", "Algeninian Winds","Burning Sea of Merres","Tangril Fire Trenches","Mosaka Cliffs","Cybernetic Moose of Veris", "Awi Light Slurper","Megu Yellers","Paper Trees of Tivi","Limi Billboard City","Lanthanamisi Dogs", "Titanium Sheep","Copper Triangle Fields","Ship Voyage Emulator (being)","Carbon Hills of Mudon","Telluriam Sea", "Trees of Affera","Anjgan Grass","Emalla Herder","Mottra Goats","Envvu Cheetah Racers", "Temusason Aqua Grass","Lenndah Hills","Velveron Bison","Kitanis Mauler Beasts","Jevleresis Space Bats", "Ilikia Ice Fields","Ommja Mammoth","Vimmasouras","Tavuru Glacial Princess","Caves of Xiiraki", "Abandoned Kelium Hills","Wandering Aluminium Grazers","Desolate Roads of Iri","Meki Transparency Grass","Humanoid Vrass Cargo Collectors", "Fields of Binary Grass","Nanocore Mountains","Helpasidis Tree Eater","11111111R11 Helium Wind Dwellers","Musoko Number Merchants", "Sunken California Coast Diving Cliffs","Nile River Riverbed Dance Club","Ankis Brand Mechanical Wild Tiger","Trapsis Foods Genetic Burger Cow","Amazon Rainforest Concrete Overlay Simulation", "Kentra Industries Electrolysis Fields","Section 78 Area 42 Oxygen Chambers","Section 19 Area 56 Oxygen Chambers","Water Extraction Algae","Dekra W566 Planetary Dust Storm", "Ultronakis Sound Worm","Metikasis Time Harvester","Shema Duality Dust","Petresis Warp Birds","Hungubria Chantillas"];

    //   uint l = s.length;
    //   uint i;
    //   string memory t;

    //   while (l > 0) {
    //       uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //       i = v % l--;
    //       t = s[l];
    //       s[l] = s[i];
    //       s[i] = t;
    //   }

    //   r = s;

    //   return r;

    // }

    // Shuffle currency assets

    // function sI(uint256 tokenId) internal view returns (string[75] memory) {

    //   string[75] memory r;
    //   string[75] memory s = [".000089 www89",".14765 www90","mutila dark emeralds x 14","sonalis gateway key",".00034 pestriaks", "84 Peka Shells","Misalik Tokens x 14.57","Bag of Terbium","Promethium Squares","0.00067 Tankil Bars", "#978BC4 Coins x 62398","0.67786766 #E8BF8B","8746 #E7D27C","Endratis Tokens x 890000","Rialis Gateway Key", "634284 Ubua Gems","Zophresis Micro Reversal Clocks x 19","Memory Stones of Inxatis x 6","Inxatis Shovel","79.45 Enci", "Tomril Ounces","Kajella x 457","Tiva Bags x 6790","Belsim Water","Stream of Andra Capsules", ".000675 Tu","7900 Imeki","Tine Wind Grounders","Glasses of Fandoki (Stolen)","Megarin Stone Grinder", "4 Gemarin","9,000,000,000,000 iii","4.6 kilograms Thallium","Jenvaril Eye Protector","14 Iridacii", "467.89999 Tankis","Sifted Delphis Dirt x 89","Mektra Tarps x 14","2600 Centra","3.4 Welini", "256 Ultriia","1400 Miniia","167 Nubatron Semas Stones","89 Selfina Amulets","Jikila Ayelia Cloth", "78.5 Dranisi","20 Fettra Climbing Nails","Eijja Bartering Coins x 900","Modu Evja Gas Heater","Six-Hour Frost Storm Off-Planet Pass x 12", "999.03456 Esi","22,009,023 Trika","Copper Monra x 50","Silver Monra x 80","Soap of Jupi", "1256892 Musoka","500 hekagrams Binary Diamond Shaving","Semi Infinite Memory Array x 46","Aragon CPU Voucher","Zencilla Passage Coins X 10", "0.23 Bitcoin","4 Ethereum","$517.30","812 Tesla Inc. Shares","12 Attica Greece Silver Tetradrachm Coins", "491 Mars Coin","Okratis Go-Ship Personal Oxygen Canister","14.7 liter water vouchers","Lithium Battery Pack x 5","3400 Solar Hour Credits", "Thekesis Propsolsion Fluid","Takilis Emeralds x 42","Somesis Transport Pass","Horizontal Allegiance Evasion Star Maps","Asteroid 4132 Palladium Coins x 76"];

    //   uint l = s.length;
    //   uint i;
    //   string memory t;

    //   while (l > 0) {
    //       uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //       i = v % l--;
    //       t = s[l];
    //       s[l] = s[i];
    //       s[i] = t;
    //   }

    //   r = s;

    //   return r;

    // }

    // Shuffle transportation

    // function sJ(uint256 tokenId) internal view returns (string[75] memory) {

    //   string[75] memory r;
    //   string[75] memory s = ["Stam Drill","reverse Mulkano crawler","opaque 222iTFKC ground divider","MakMak dust shoes","k6k6 dust propelled moon shuttle", "Seffa Cruiser","Venki Surface Ejector","Thamarian Wind Glider","Chlorine Sea Hover Circle","Fastril Nebula Parachute", "Mogrid Fuel Bus","Vena Lunar Shuttle","Patellic Fighter Ship","EAR Probe","Sea of Tell Ferry", "Thorium Blade Ship","Angress Blast Capsule","Messason Agerin Sea Cargo Ship","TYIUNFLK Research Vessel","Vegerathi Evader", "Ettra Fire Navigator","Varis Glacial Capsule","Metris Valley Darkness Evader","Igalis Hover Ship (Stolen)","Emntra Ice Horse", "Velshin Van","Canvil Billboard Installer (Stolen)","704 Cascadian Land Patroller","Tellrium City Board","Limi Light Orb", "14 Iridacii","Thallium Propeller Boat","Anriva Ground Tank","Betri Carbon Shoveller","Hydrogen Moon Evacuator", "Tenna Plough","Tenna Land Traverser","Agelin Sand Shoes","Muskadon Sky Hook","Ikandro Elevation Glider", "Velmos Shuttle","Numbatron Stellar Craft","Numbatron Mesatil Launcher","Ravesin Basin Crawler","Night Flight Trasik Plane", "Atteris Snowmobile","Tra Laser Blast Valley Skaters","Envil Ice Destroyer Ship","Ice Cave Crawler","Low Hover Messaviactus Ship", "Makri Tractor","Vrass Cargo Loader (modified)","Jemli Car","Meska Moon Runners","Avesis Transportation Pass", "Kentris Shipping Crate","11111R1 Gravitational Loop","Vemula Quantum Bus Depot","1118000R Oil Absorbent Shuttle","Hefshin Moon Magnet Glider", "1976 Buick Electra Limited","Helratian Photon Solo Avenger (Stolen)","2000 Hummer H1 Limited Edition","1977 Fiat 124","3029 Tesla Model S SpaceX Galactic Thrust Edition", "Microbial Sample Rover (Stolen)","Enceladus Exploration Ship","Magnetic Hover Vehicle","Intra-colony Capsule System","NASA Ignition Booster Red Suit", "Helratian Vortex Navigator (Stolen)","Metruliae Thrust Fighter","Vertex Gas Inter-Station Voyager","Helu Beam Sand Nebula Blaster","Tamrisian Speed Destroyer"];

    //   uint l = s.length;
    //   uint i;
    //   string memory t;

    //   while (l > 0) {
    //       uint256 v = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
    //       i = v % l--;
    //       t = s[l];
    //       s[l] = s[i];
    //       s[i] = t;
    //   }

    //   r = s;

    //   return r;

    // }

    // Generate intergalactic backpacks

    // function gA(uint256 tokenId) private view returns (string memory) {

    //     string[5] memory r;
    //     string memory u;
    //     uint l = 75;
    //     uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

    //     for (uint a = 0; a < 5; a++) {

    //         string[75] memory h = sC(tokenId);
    //         uint256 x = q % l--;
    //         r[a] = h[x];
    //         l--;

    //     }

    //     string memory c;
    //     c = r[0];

    //     string memory d;
    //     d = r[1];

    //     string memory e;
    //     e = r[2];

    //     string memory f;
    //     f = r[3];

    //     string memory g;
    //     g = r[4];

    //     // now I have the array R
    //     u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
    //     return u;

    // }

    // Generate allies

    function gB(uint256 tokenId) private view returns (string[5] memory) {

        string[5] memory r;
        // string memory u;
        uint l = 75;
        uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

        for (uint a = 0; a < 5; a++) {

            string[75] memory h = sB(tokenId);
            uint256 x = q % l--;
            r[a] = h[x];
            l--;

        }

        return r;

        // string memory c;
        // c = r[0];

        // string memory d;
        // d = r[1];

        // string memory e;
        // e = r[2];

        // string memory f;
        // f = r[3];

        // string memory g;
        // g = r[4];

        // // now I have the array R
        // u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
        // return u;

    }


    // Generate nemeses

    function gC(uint256 tokenId) private view returns (string[5] memory) {

        string[5] memory r;
        // string memory u;
        uint l = 75;
        uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

        for (uint a = 0; a < 5; a++) {

            string[75] memory h = sC(tokenId);
            uint256 x = q % l--;
            r[a] = h[x];
            l--;

        }

        return r;

        // string memory c;
        // c = r[0];

        // string memory d;
        // d = r[1];

        // string memory e;
        // e = r[2];

        // string memory f;
        // f = r[3];

        // string memory g;
        // g = r[4];

        // // now I have the array R
        // u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
        // return u;

    }

    // Generate damage intoxication

    function gD(uint256 tokenId) private view returns (string[5] memory) {

        string[5] memory r;
        // string memory u;
        uint l = 75;
        uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

        // string[75] memory h = sD(tokenId); // added
        for (uint a = 0; a < 5; a++) {

            string[75] memory h = sD(tokenId);
            uint256 x = q % l--;
            r[a] = h[x];
            // delete h[x]; // added
            l--;

        }

        return r;

        // string memory c;
        // c = r[0];

        // string memory d;
        // d = r[1];

        // string memory e;
        // e = r[2];

        // string memory f;
        // f = r[3];

        // string memory g;
        // g = r[4];

        // // now I have the array R
        // u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
        // return u;

    }

    // Generate weapons communication

    // function gE(uint256 tokenId) private view returns (string memory) {

    //     string[5] memory r;
    //     string memory u;
    //     uint l = 75;
    //     uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

    //     for (uint a = 0; a < 5; a++) {

    //         string[75] memory h = sC(tokenId);
    //         uint256 x = q % l--;
    //         r[a] = h[x];
    //         l--;

    //     }

    //     string memory c;
    //     c = r[0];

    //     string memory d;
    //     d = r[1];

    //     string memory e;
    //     e = r[2];

    //     string memory f;
    //     f = r[3];

    //     string memory g;
    //     g = r[4];

    //     // now I have the array R
    //     u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
    //     return u;

    // }

    // Generate shields protection

    // function gF(uint256 tokenId) private view returns (string memory) {

    //     string[5] memory r;
    //     string memory u;
    //     uint l = 75;
    //     uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

    //     for (uint a = 0; a < 5; a++) {

    //         string[75] memory h = sC(tokenId);
    //         uint256 x = q % l--;
    //         r[a] = h[x];
    //         l--;

    //     }

    //     string memory c;
    //     c = r[0];

    //     string memory d;
    //     d = r[1];

    //     string memory e;
    //     e = r[2];

    //     string memory f;
    //     f = r[3];

    //     string memory g;
    //     g = r[4];

    //     // now I have the array R
    //     u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
    //     return u;

    // }

    // Generate surrounding space bases

    // function gG(uint256 tokenId) private view returns (string memory) {

    //     string[5] memory r;
    //     string memory u;
    //     uint l = 75;
    //     uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

    //     for (uint a = 0; a < 5; a++) {

    //         string[75] memory h = sC(tokenId);
    //         uint256 x = q % l--;
    //         r[a] = h[x];
    //         l--;

    //     }

    //     string memory c;
    //     c = r[0];

    //     string memory d;
    //     d = r[1];

    //     string memory e;
    //     e = r[2];

    //     string memory f;
    //     f = r[3];

    //     string memory g;
    //     g = r[4];

    //     // now I have the array R
    //     u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
    //     return u;

    // }

    // Generate landscape beings creatures

    // function gH(uint256 tokenId) private view returns (string memory) {

    //     string[5] memory r;
    //     string memory u;
    //     uint l = 75;
    //     uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

    //     for (uint a = 0; a < 5; a++) {

    //         string[75] memory h = sC(tokenId);
    //         uint256 x = q % l--;
    //         r[a] = h[x];
    //         l--;

    //     }

    //     string memory c;
    //     c = r[0];

    //     string memory d;
    //     d = r[1];

    //     string memory e;
    //     e = r[2];

    //     string memory f;
    //     f = r[3];

    //     string memory g;
    //     g = r[4];

    //     // now I have the array R
    //     u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
    //     return u;

    // }

    // Generate currency assets

    // function gI(uint256 tokenId) private view returns (string memory) {

    //     string[5] memory r;
    //     string memory u;
    //     uint l = 75;
    //     uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

    //     for (uint a = 0; a < 5; a++) {

    //         string[75] memory h = sC(tokenId);
    //         uint256 x = q % l--;
    //         r[a] = h[x];
    //         l--;

    //     }

    //     string memory c;
    //     c = r[0];

    //     string memory d;
    //     d = r[1];

    //     string memory e;
    //     e = r[2];

    //     string memory f;
    //     f = r[3];

    //     string memory g;
    //     g = r[4];

    //     // now I have the array R
    //     u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
    //     return u;

    // }

    // Generate transportation

    // function gJ(uint256 tokenId) private view returns (string memory) {

    //     string[5] memory r;
    //     string memory u;
    //     uint l = 75;
    //     uint256 q = z(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

    //     for (uint a = 0; a < 5; a++) {

    //         string[75] memory h = sC(tokenId);
    //         uint256 x = q % l--;
    //         r[a] = h[x];
    //         l--;

    //     }

    //     string memory c;
    //     c = r[0];

    //     string memory d;
    //     d = r[1];

    //     string memory e;
    //     e = r[2];

    //     string memory f;
    //     f = r[3];

    //     string memory g;
    //     g = r[4];

    //     // now I have the array R
    //     u = string(abi.encodePacked(c, " / ", d, " / ", e, " / ", f, " / ", g));
    //     return u;

    // }

    // Backpack emoji

    function getBackpack() public pure returns (string memory) {
        string memory backpack = unicode"🎒";
        return backpack;
    }

    // Titles

    function gT() private pure returns (string[3] memory) {
        string[3] memory t;
        // t = ["intergalactic backpack", "allies", "nemeses", "damage.intoxication", "weapons.communication", "shields.protection" , "space.bases", "landscape.beings.creatures", "currency.assets", "transportation"];
        t = ["allies", "nemeses", "damage.intoxication"];

        return t;
    }

    // Token URI

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[39] memory p;
        // p[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 3600 1350"><style>.h {fill: white; font-family: serif; font-size: 72px;} .g {fill: white; font-family: serif; font-size: 48px;} .y {fill: white; font-family: serif; font-size: 34px;} .t {fill: gray; font-family: serif; font-size: 28px;} .i {fill: white; font-family: serif; font-size: 38px;} { .b {font-size: 48px;}</style><rect width="100%" height="100%" fill="black" /><text x="50" y="100" class="h">';
        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 700 700"><style>.t {fill: gray; font-family: serif; font-size: 10px;} .i {fill: white; font-family: serif; font-size: 14px;} .b {}</style><rect width="100%" height="100%" fill="black" /><text x="50" y="50" class="t">';

        p[1] = gT()[0];

        p[2] = '</text><text x="50" y="70" class="i">';

        p[3] = gB(tokenId)[0];

        p[4] = '</text><text x="50" y="90" class="i">';

        p[5] = gB(tokenId)[1];

        p[6] = '</text><text x="50" y="110" class="i">';

        p[7] = gB(tokenId)[2];

        p[8] = '</text><text x="50" y="130" class="i">';

        p[9] = gB(tokenId)[3];

        p[10] = '</text><text x="50" y="150" class="i">';

        p[11] = gB(tokenId)[4];

        p[12] = '</text><text x="50" y="190" class="t">';

        p[13] = gT()[1];

        p[14] = '</text><text x="50" y="210" class="i">';

        p[15] = gC(tokenId)[0];

        p[16] = '</text><text x="50" y="230" class="i">';

        p[17] = gC(tokenId)[1];

        p[18] = '</text><text x="50" y="250" class="i">';

        p[19] = gC(tokenId)[2];

        p[20] = '</text><text x="50" y="270" class="i">';

        p[21] = gC(tokenId)[3];

        p[22] = '</text><text x="50" y="290" class="i">';

        p[23] = gC(tokenId)[4];

        p[24] = '</text><text x="50" y="330" class="t">';

        p[25] = gT()[2];

        p[26] = '</text><text x="50" y="350" class="i">';

        p[27] = gD(tokenId)[0];

        p[28] = '</text><text x="50" y="370" class="i">';

        p[29] = gD(tokenId)[1];

        p[30] = '</text><text x="50" y="390" class="i">';

        p[31] = gD(tokenId)[2];

        p[32] = '</text><text x="50" y="410" class="i">';

        p[33] = gD(tokenId)[3];

        p[34] = '</text><text x="50" y="430" class="i">';

        p[35] = gD(tokenId)[4];

        // p[36] = '</text><text x="50" y="990" class="i">';

        // p[37] = gC(tokenId)[4];

        // p[38] = '</text><text x="50" y="1037" class="t">';

        // p[39] = gT()[8];

        // p[40] = '</text><text x="50" y="1080" class="i">';

        // p[41] = gI(tokenId);

        // p[42] = '</text><text x="50" y="1127" class="t">';

        // p[43] = gT()[9];

        // p[44] = '</text><text x="50" y="1170" class="i">';

        // p[45] = gJ(tokenId);

        p[36] = '</text><text x="650" y="650" class="b">';

        p[37] = getBackpack();

        p[38] = '</text></svg>';

        string memory u = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]));
        u = string(abi.encodePacked(u, p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16]));
        u = string(abi.encodePacked(u, p[17], p[18], p[19], p[20], p[21], p[22], p[23], p[24]));
        u = string(abi.encodePacked(u, p[25], p[26], p[27], p[28], p[29], p[30], p[31], p[32]));
        u = string(abi.encodePacked(u, p[33], p[34], p[35], p[36], p[37], p[38]));
        // u = string(abi.encodePacked(u, p[41], p[42], p[43], p[44], p[45], p[46], p[47], p[48]));
        // u = string(abi.encodePacked(u, p[57], p[58], p[59], p[60], p[61], p[62], p[63], p[64]));
        // u = string(abi.encodePacked(u, p[65], p[66], p[67], p[68], p[69], p[70], p[71], p[72]));
        // u = string(abi.encodePacked(u, p[73], p[74], p[75], p[76], p[78], p[79], p[80], p[81]));
        // u = string(abi.encodePacked(u, p[82], p[83], p[84], p[85], p[86], p[87], p[88], p[89]));
        // u = string(abi.encodePacked(u, p[90], p[91], p[92], p[93], p[94], p[95], p[96], p[97]));
        // u = string(abi.encodePacked(u, p[98], p[99], p[100], p[101], p[102], p[103], p[104], p[105]));
        // u = string(abi.encodePacked(u, p[106], p[107], p[108], p[109], p[110]));
        // u = string(abi.encodePacked(u, p[114], p[115], p[116], p[117], p[118], p[119], p[120], p[121]));
        // u = string(abi.encodePacked(u, p[122], p[123], p[124], p[125], p[126], p[127], p[128]));
        // output = string(abi.encodePacked(output, p[25], p[26], p[27], p[28], p[20], p[20], p[20], p[20]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Intergalactic Backpack Pack One #', toString(tokenId), '", "description": "No one makes it out alone! Watch out for your nemeses and the damage and intoxication they cause! Keep going. There is another pack coming up soon.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(u)), '"}'))));
        u = string(abi.encodePacked('data:application/json;base64,', json));

        return u;
    }

    // to String utility

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}