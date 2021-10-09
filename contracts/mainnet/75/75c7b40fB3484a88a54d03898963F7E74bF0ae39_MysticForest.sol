// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MysticForest is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 private tokenPrice = 30000000000000000; //0.03 ETH
    uint256 private constant nftsNumber = 3333;

    constructor() ERC721("Mystic Forest", "MFS") {
        _tokenIdCounter.increment();
    }
     
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function toHashCode(uint256 value) internal pure returns (string memory) {
        uint256 i;

        bytes memory buffer = "000000";
        for(i=6;i>0;i--) {
            if (value % 16 < 10)
                buffer[i-1] = bytes1(uint8(48 + uint256(value % 16)));
            else
                buffer[i-1] = bytes1(uint8(55 + uint256(value % 16)));

            value /= 16;
        }
        return string(buffer);
    }
    
    
    function getSun(uint256 num) internal pure returns (string memory) {
        uint256 suns;

        suns = 733410643314582114512314603012454017743510734712492414;

        if (num > 0)
            suns = suns / (100 ** (num*3));

        return string(abi.encodePacked('cx="',toString(10*((suns/10000)%100)),'" cy="',toString(10*((suns/100)%100)),  '" r="',toString(10*(suns%100)),'"'));
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
    
    function toStringSgn(int256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        int256 temp = value >= 0 ? value : -value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        if (value < 0) {
            digits++;
        }
        bytes memory buffer = new bytes(digits);
        if (value < 0) {
            //digits -= 1;
            value = -value;
            buffer[0] = bytes1(uint8(45));
        }
        
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
    
    function getPoints(uint256 num, uint256 dir) public pure returns (string memory ) {
        uint256[181]memory xtypes =[
            451793160510049142483918980479775049983908311004982111838287590179673737989,
            14118699526057964743410206948092109528394018437505512525414365549665044271,
            2990036367364346621795866131653571121699026289141046,
            2846959607925562073345508372401376781316743025224824348287758227432596905387,
            2992194365839321942769086036007447618697968584327369,
            3753734288543931459086705196516412049375550376183621772483166746286184606530,
            3597369614550173525007166796257012767273641370844282701925507925543792285476,
            3075761135342858797770537856738277071188091692804336596343286722299200667402,
            3271440244353497429621230532185176914974600625852871336223639350182882160947,
            3567277993316903498903678063180104354953965719249179472654654856748081471205,
            14116380865331896385391450086178179633152641401541680509438725334071115455,
            2928482646864365553151142455467482501976710809299108047461350705223466036572,
            3821675339075292395182255302395855070914232488246053891403721248044174656656,
            3115984019240715960323244328181115455415043147489357163259133709542708861632,
            3244496427842502701626018574735712370044808469909759174473139369101112483559,
            2987353119357672916579205987982357504557173396589332,
            2324379648625379036385613574183488699472078952337521869568077904426458695082,
            1217389987403007936526409203484901692820865472055694339022933326868434208476,
            2417010777913069026691127,
            3441913708957137518381877344345889930126595129725057885264505170531043574126,
            2917600651716002271669893996375613785659812323984791490780495802912166578946,
            3708293718636760152364718089342064469940324999664627799228079694530507806907,
            14110665356844149303507105224900996936092881811303175606715491365591308984,
            3158444373777377413788230076701033876397915336301543208713906208600121680810,
            2817275567468375932596139929010515239344556343459808531647085207214086288099,
            6033198342414225328300838243277501079158001050375815138405344997606103814822,
            511,
            2720100494981947149539386702781528929757544005649907703010181904670973973504,
            2408277705204458091040044302132094573526111473190295366598038857750651699947,
            14107169532839929700752091609538676282944105693729639298668804927339193532,
            1221861636475146439091757024136704920792770829275233582034370279380946780480,
            1929745078649056008424622866595262801745570856914548905876583021709899361596,
            4191612511679389882886921941088289735083347780575901480897275437039305163532,
            4343672155361759899968976175801058502330943465806784759312473237134593393414,
            3566948221669800087678086064374772626813770766313968875691818267877922725523,
            2844054930834458621500612357249982365132495895267457727130737277089430495386,
            2831495325425439623070653177758459898886181703506414534104480167890488760425,
            1939784730250891792929893416777521507641579746635591985114370828684217120906,
            710500672182797626540852971474592761735170912982147831611021980890913641100,
            669528245421993200021192424975553018500427455508620586550532192993530410145,
            2786907874801123243278384440540569289884967736012447883743896884908079991958,
            783107716654838027593076735110698867723631140942751048784,
            1223742098789066363086146454490327367432992460366389926123382679180957712679,
            2989461533470413134394949618378485716466310952657952709026655806765503873313,
            4078587196827700236148252441598457738652016331251713638460871880042585108753,
            4093662014144226772182022731933318239401904060323200219570934945711682620714,
            4418350303103987658838040236072521517526306626247445323272330839020818545973,
            4643374242505799556552622217641105384457783205137552427483606424730257476378,
            4486704919427852534038064683873585202257802529007438651353378708385046889726,
            4499817856359707397730280519483643102692499149107402831319735562894054958274,
            4485047847576554290163471944750006657681399132671410856687041433809695181498,
            3339683520300060376447863508244732503262915016529560249180018002256610357913,
            4314878010312732853382723482941746333872906915161246828553891387663095579798,
            4074365359127156374762978298570824350410250584226094189806368457852740328077,
            2436326669430798195291140631745346883464912839142971982342415690991918792828,
            2844633605229433334766034265509774244631325963311003701214089162068265098949,
            6021414796764815790125087145808661297551719617535403347668275848711477729927,
            35115764503978,
            2294397700659397197699685406473997836554794841367326523950238727322888134340,
            2025283187394261770417930627778433871681276905838016306264739971388040888997,
            2139603985908275075394494527883218115071698703519051893093505600987932723858,
            1602149956337663419398244079233223101532761471563090164321742541338988053665,
            738518038087913997980297120834578920434720559540340738145828685906757868759,
            1021903637670771945756436204332950418418658165449833330825908986328191100032,
            680321428688133661527588016944122147941545355974128538876479717265524186287,
            2913459048355080754922760102631198697031511036604646793395992893426023029303,
            3479130709408447676265801231112877966675791703322346548396001197341351923258,
            3253854748105555120936084797666487228976513545459761200829578045966826558534,
            1699189092874344557865822570537512574159152442335308490674709866561864328806,
            667400986628054122756790148927330777523787572677566916314191737094336736856,
            2873236813626440676171292303262262666143114256158109036142099440858322466905,
            2463849106514764934759999084079940125420965362783417301190030635058228465285,
            205438914033105927166860879746299341319617056510616058071714482,
            1038298747581850190237060263176966035035230656825643754185710646059835386620,
            3732457000988826922007756981740258362491522747964965354310174111752044251,
            3438103229906894537734127924212645170137014733982627380114740921114531725405,
            6026623316013678363917195968975149767749651216939496676609297726456481298556,
            2241115314331019743849717121383702017708454573017073812756468592096814519488,
            2681337874473351023978523739001495494271733781408597532984622975686384632096,
            2001763240303821190799393538957491125291823459084909037776275767301748935526,
            783413015098298932391713953208811102504075259788668508482,
            2776969648718084143666140509500198189279833454686509566456828797242640011984,
            2414986924677709585549545,
            2464981860802702008248797613075615501215516799470075317970249081860416421077,
            2790303763375407904938366532926037490714110175281242670150366813065796212937,
            2465617633008893670180232371899505684333818314842213059041399293168815016146,
            11401324657414517125554847765234191730741173982,
            2007586617321629222923565623524787798034647400175032804774855609950202812116,
            1672990505318255906211175434427645236074840599879267478213906817477142731280,
            9209241678118184635,
            3468278804203466157829532655206811853319359876474512079669760097188562518207,
            3368092997782354757286082990925204154758011631855831233655982736879923093696,
            3466927620119320294039074189203980316785782842647169496311690405307103440018,
            5997944131679293691663553390168068182099797190984646160656605843082062729358,
            166052324687270284571457507386895010,
            3085920706480894367934793525780658400280345745353555300919491971404221773981,
            3381923554997078344785988371461154782062075902541709693502099696739921014948,
            3325992182572119952955425236755568253968694395336855696455540407431783377038,
            3580226521759520107286065368001833307388687503078515293404116916742493691037,
            9214447060903921835,
            1264984556772872115799239535623524884253620648193824583495524875928754752372,
            1518694096269015099096880765822086114228988044590962307891613193926223639292,
            14108292701559715841792991169612211414500920245362129234577009518961809647,
            4402309342509142896983013934442726920810334999082253451627659966777804363614,
            5166666755085030868803444639761683845012503598362881109034321078214982796000,
            5209789353333249880387445761925302865630999691231556305081968356544667639561,
            4687711984736242421744479873093886204824147798593512993564205989451328829754,
            633401437854182220628048116557,
            4160112497456759832337992694410202976874104741130252497257247851041788420278,
            3891799183155487259340119950380455072303927206702853094379188893373129184420,
            4032319059663099998613520512820426697785970979928996764016646343459105024168,
            6009124949811886177795131206969081357356598945839022389523915066407043351690,
            4372824752384694282188496870332751107712575766430818661088545374422765321323,
            511,
            4572783505867648305281967398068273625119110075055536844749714995321564755266,
            4911328827335463014379332819972782815283711440757324548670808260875358996733,
            4954975634469296598514925777471018546955821345030274703468035996303540008180,
            9218679515535855434,
            3452321906512025464371802897836094518801199388935465272003231966772078459556,
            3748795261402758157788885492974445466658083400195392878155357454986132445816,
            3693223752333072151459562658612960597342516520193788012145779387957259162222,
            166100478298923491154776583125472921,
            4106912717246667397226625890641599430529090592382302926370216293486154887481,
            3908087369193035517127117204590882787971039887165197271342261232177579172126,
            4019730387115211301930848795814057164513472405301479405129673201161948762874,
            4018018908936592607058282959488975987548663007885063821141157517257090944708,
            4089300309602240007959434644505762866602904250751726411778648112543795920524,
            4315071312289070109850147802022436970240917711138035951472706131873335498401,
            4725202305958257607474266791898393255878424154030894468088061083124026994324,
            4683680110174487984206714084092740316576662890866513069791112855826925306027,
            4457910940450972001776820480444395513452836462258651691797388206013323572411,
            5914901893015460913288455038769590541213807873541693763162803986498813334735,
            5873017302155366219580613819295633263556778663954408054822111840194936602855,
            4785246056814329393415455871264870088767110637544142448838340819902228544776,
            53873736278750663526986526463830033766076938107653441239559073616152,
            3961230583850472195613434616701520650168113370266317092807283110795912059980,
            4159974300347659916450908224181423693787057029892764815291476147123686097536,
            4696849232163410979886557344830309530276030548981272388554922402907907053214,
            4555252517360058801235317977916661134159115037001481971805637241651654724760,
            4555280178158998160895654468742184453035832431543937761396878704524961674893,
            4682797599279848964386326277705955728837885892369600134905466615452314795661,
            2991124662820466729985366582785995318337604215546002,
            4094794229538461950196996980986282399454829575579897639099107199351723801495,
            4488498896934177163671566746299360720998703618133128471784444635917868747625,
            4870470494855650238260992884771850191437967751124123170685490486885430760267,
            4996414205762082127019268313479351099601209822643463938109046716488425055526,
            4374315480207661070076200965843976990402875250847505604199786248963436759813,
            4993487853199467340812965741758286970078604087317064681517188962153421756119,
            4611709501646942332033416691737330215799267808709507583702922506831535976105,
            4553457678274957529173455164972517555198985209347470674437518245996323048065,
            3983655792221959106678542874491535023802240994398748708194091973432699153987,
            511,
            2751764049184355665970427661834368826893000635972708917258254524379653095834,
            3996762043688216515082017709646178332496394459296666445946293863156097062241,
            3854557703404383100840836971486404259590598414489461376417567508339986407800,
            3401413784224831724878919757846841118321199606089710978620901144409073395044,
            4419424766817352224692370267239741687023769241515970830156920086838702632782,
            3669119147830135099252246142986051209252166546386211128736251135120952430949,
            4036708964316911879340196539985070616330457410477349779590474447422696063757,
            4786904208120125539628028421123318453534542575865124491913205630904344135979,
            4927010409629265575240327547968006977797442604613099202290221307456865605964,
            4530848496956884285912366022076978316699445255927116468642440159401239554349,
            4897830200248151060304598534559494633163927757987279030443661669629025228570,
            4982141284371903555041559258627467217052791415694756268205937693649074559228,
            5051104011357210160921999575117301746262595505134723231406126068278101469919,
            4428758230533668701111108424422998856252086733747575715414198910256133618362,
            4555916003654641992253243995961629462190195338819898436721465933797476443822,
            4922316665112551244551227182538960607585056393399270553803496721819810573972,
            4526017686709248224619740044776819724367225939391434944440434506284260568183,
            3904388555610503058690726102571162509580816304148758661208200338363226694753,
            4610329741180249610163619688882547569496715425741848059399482580093453349996,
            4369816174511426972967861755239262887278514684876866413910128789616023209563,
            3677346549089972577976174802446580897876944132670129399346325781540561909838,
            3408261474405718409088466451838629603401564969655245534647691783341921921622,
            165976556783559723167202694497953337,
            2990235126345283631822877804924730718839988305133692,
            43513319658703679254636568203538827443336,
            43522980609105388572596600985827531712216,
            43522146275689570242343825481909074813128,
            11408759685182567224012020944406186655893315218,
            11408934930604125130349902336635238117986951321
            ];
        uint256 i;
        uint256 first_index;
        uint256 cur_num;
        uint256 k;
        int256 dir_y;
        uint256 pos;
        string memory res;
        uint256 result;
        
        first_index = num < 3 ? num+1 :  (xtypes[0] / (256 ** (num-3)))%256;
        
        if (dir==1)
            dir_y = 140;
        else
            dir_y = 900;
        res = '';
    
        for(i = first_index; i<=181; i++) {
            if (xtypes[i] == 0)
                break;
    
            cur_num= xtypes[i];    
            k=0;
            for(pos=0;pos<=27;pos++) {
                result = (cur_num /  (512 ** pos)) % 512;
                if (result == 511)
                    break;
    
                if (k%2 == 0) {
                    if (dir==1)
                        res = string(abi.encodePacked(res, toStringSgn(int256((result*3))-140), ','));
                    else
                        res = string(abi.encodePacked(res, toStringSgn(1250-int256((result*3))), ','));

                }
                else {
                    res = string(abi.encodePacked(res, toStringSgn(int256((result*3*dir))-dir_y), ' '));

                }
                k++;
             }   
            if (result == 511)
                break;
        }

        return res;
    }
    
    function tokenURI(uint256 tokenId) pure public override(ERC721)  returns (string memory) {
        uint256[19] memory xtypes;
        string[5] memory colors;

        string[15] memory parts;
        uint256[12] memory params;

        uint256 pos;

        uint256 rand = random(string(abi.encodePacked('Forest',toString(tokenId))));

        params[0] = 1 + (rand % 36); // pallette=
        params[1] = 1 + ((rand/100) % 9);// mount
        params[2] = 1 + ((rand/1000) % 2); // savanna
        params[3] = 1 + ((rand/10000) % 2); // tree1
        params[4] = 1 + ((rand/100000) % 2); // tree2
        params[5] = 1 + ((rand/1000000) % 9); // animal
        params[6] = 1 + ((rand/10000000) % 9); // monster
        params[7] = 1 + ((rand/100000000) % 2); // grass
        params[8] = 1 + ((rand/1000000000) % 9); // sun
        params[9] = 1 + ((rand/10000000000) % 20); // METEOR
        if (((rand/10000000000) % 20) == 1) // rare palette
            params[0] = 37 + params[0]%2;

        xtypes[0] = 1380184997384756203389348097935548270238418335313894369135963045576512;
        xtypes[1] = 83202958701067158272510542586996495922438516550026878711368311707271070;
        xtypes[2] = 110890097058345544686991556799584296435994298503832019423597570805434368;
        xtypes[3] = 124747513234871200025641583470717623407926130169324315491794011723611968;
        xtypes[4] = 172545869938643596635233103058992932872987519665270880114754418406014784;
        xtypes[5] = 62901452128639038462844002121514286276591308821405480058892378347355968;
        xtypes[6] = 6906312258075195189521669129432903118929838785118276903637969883103134;
        xtypes[7] = 34644103446304817287021645401906549158943647054285149371488762479984448;
        xtypes[8] = 460428004036880295485476712922934712833987410898445681727580956905712;
        xtypes[9] = 165644650256154674906236099093466854341981357834224037341526031155019069;
        xtypes[10] = 568830213016122120965376512587328509977555256782756811911715291660190;
        xtypes[11] = 408475849166444685717692499863891921759522907256683076899882642964479;
        xtypes[12] = 138036611714692334195370901026278071274391887700961563656694752681606976;
        xtypes[13] = 138036611664120373689974417613175875397870210537061667156895429971376248;
        xtypes[14] = 164484919190898338221032560993011736145912193578603571776097733172223;
        xtypes[15] = 262270363244384067749521393870671431072564228073668465975395327494012736;
        xtypes[16] = 372697461957250082012985360966108567877767279094447770984938832788406080;
        xtypes[17] = 404941104510058468213265706796467786427704521430213011681667002136491;
        xtypes[18] = 33834578429608361535043529526350847219631511783612495748003004329;

        if (params[9] <= 7) {
            for(pos=0;pos<1+params[9]/2;pos++) {
                parts[14] = string(abi.encodePacked(parts[14], '<circle opacity="0.4" fill="#FFFF9E" cx="',toString(400 + pos*150),'" cy="-',toString((69+pos*200)%275),'" r="4"/>'));
            }
            parts[14] = string(abi.encodePacked('<g>',parts[14],'<animateMotion path="M 0 0 l ',(params[9]%2==0?'':'-'),'10000 10000 20 Z" dur="20s" repeatCount="indefinite" /> </g>'));
        }
    
        pos = (params[0]-1) * 5;
        colors[0] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
    
        pos = (params[0]-1) * 5 + 1;
        colors[1] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[0]-1) * 5 + 2;
        colors[4] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[0]-1) * 5 + 3;
        colors[3] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        pos = (params[0]-1) * 5 + 4;
        colors[2] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        
        parts[0] = '<?xml version="1.0" encoding="utf-8"?> <svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" width="1000px" height="1000px" viewBox="0 0 1000 1000"> <linearGradient id="B" gradientUnits="userSpaceOnUse" x1="500" y1="1000" x2="500" y2="0"> <stop offset="0" style="stop-color:#'; // 1
        parts[1] = '"/> <stop offset="0.5" style="stop-color:#'; // 2
        parts[2] = '"/> <stop offset="1" style="stop-color:#'; // 1
        parts[3] = string(abi.encodePacked('"/> </linearGradient> <rect fill="url(#B)" width="1000" height="1000"/> <radialGradient id="S" ',getSun(params[8]-1),' gradientUnits="userSpaceOnUse"> <stop offset="0.75" style="stop-color:#FFFF9E"/> <stop offset="1" style="stop-color:#')); // 2
        parts[4] = string(abi.encodePacked('"/> </radialGradient> <circle opacity="0.9" fill="url(#S)" ',getSun(params[8]-1),'/> ',parts[14], '<polygon opacity="0.14" fill="#')); // 3
        parts[5] = string(abi.encodePacked('" points="',getPoints(0+params[1]-1,1),'"/> <polygon opacity="0.6" fill="#')); // 3
        parts[6] = string(abi.encodePacked('" points="',getPoints(9+params[2]-1,1),'"/> <polygon fill="#')); // 3
        parts[7] = string(abi.encodePacked('" points="',getPoints(11+params[3]-1,1),'"> <animateMotion path="M 0 0 l 15 20 l 12 15 Z" dur="19s" repeatCount="indefinite" /> </polygon> <polygon fill="#')); // 3
        parts[8] = string(abi.encodePacked('" points="',getPoints(11+params[4]-1,2),'"> <animateMotion path="M 0 0 l 15 19 l 13 14 Z" dur="17s" repeatCount="indefinite" /> </polygon> <polygon fill="#')); // 3
        parts[9] = string(abi.encodePacked('" points="',getPoints(25+params[7]-1,1),'"> <animateMotion path="M 0 0 l 10 0Z" dur="16s" repeatCount="indefinite" /> </polygon>  <rect opacity="0" fill="#')); // 3
        parts[10] = string(abi.encodePacked('" width="1000" height="1100">',(params[6]<=3 ? '<animate attributeName="opacity" values="0;.3;.3;.4;.3;.3;0" dur="10s" repeatCount="1" begin="monster.end-10" restart="whenNotActive" />' : ''),'</rect><g opacity="0"> <polygon fill="#')); // 3
        parts[11] = string(abi.encodePacked('" points="',getPoints((params[6]<=3 ? 22 : 13)+params[(params[6]<=3 ? 6 : 5)]-1 ,1),'"/> ')); // 3
        if (params[6]<=3)
            parts[12] = string(abi.encodePacked('<polygon fill="#',colors[0],'" points="',getPoints(26+params[6]*2-1,1),'"> <animate attributeName="opacity" values="1;1;1;1;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1" dur="3s" repeatCount="indefinite" begin="0s" /> </polygon> <polygon fill="#',colors[0],'" points="',getPoints(26+params[6]*2,1),'"> <animate attributeName="opacity" values="1;1;1;1;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1" dur="3s" repeatCount="indefinite" begin="0s" /> </polygon>')); // 3
        else
            parts[12] = '<rect opacity="0" x="250" y="250" width="500" height="500"/>';
        parts[13] = '<animate attributeName="opacity" id="monster" values="0;1;1;1;1;0" dur="10s" repeatCount="1" begin="click" restart="whenNotActive" /><animate attributeName="opacity" values="0;1;0;0;0;0;0;0" dur="60s" repeatCount="indefinite" begin="30s" end="monster.start"/> <animateMotion path="M 0 0 l 0 -15Z" dur="30s" repeatCount="indefinite" /> </g></svg>';
                
        string memory output = string(abi.encodePacked(parts[0],colors[4],parts[1],colors[3],parts[2]));
        output = string(abi.encodePacked(output,colors[4],parts[3],colors[3],parts[4]));
        output = string(abi.encodePacked(output,colors[2],parts[5],colors[2],parts[6]));
        output = string(abi.encodePacked(output,colors[2],parts[7],colors[2],parts[8]));
        output = string(abi.encodePacked(output,colors[2],parts[9],colors[2],parts[10]));
        output = string(abi.encodePacked(output,colors[2],parts[11],parts[12],parts[13]));


        
        parts[0] = '[{ "trait_type": "Far", "value": "';
        parts[1] = toString(params[1]);
        parts[2] = '" }, { "trait_type": "Palette", "value": "';
        parts[3] = toString(params[0]);
        parts[4] = '" }, { "trait_type": "Savanna", "value": "';
        parts[5] = toString(params[7]*1000 + params[2] * 100 + params[3] * 10 + params[4]);
        if (params[6]<=3) {
            parts[6] = '" }, { "trait_type": "Monster", "value": "';
            parts[7] = toString(params[6]);
        } else {
            parts[6] = '" }, { "trait_type": "Animal", "value": "';
            parts[7] = toString(params[5]);
        }
        parts[8] = '" }, { "trait_type": "Sun", "value": "';
        parts[9] = toString(params[8]);
        if (params[9]<=7) {
            parts[9] = string(abi.encodePacked(parts[9],'" }, { "trait_type": "Meteor", "value": "', toString(params[9])));
        }
        parts[10] = '" }]';
        
        string memory strparams = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        strparams = string(abi.encodePacked(strparams, parts[6], parts[7], parts[8], parts[9], parts[10]));



        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Mystic Forest", "description": "Mystic Forest - interactive game, completely generated OnChain","attributes":', strparams, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    function claim() public  {
        require(_tokenIdCounter.current() <= 300, "No more free tokens");
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function buyTokens(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= 30, "Not more 30");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsNumber, "Sale finished");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Need more ETH");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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