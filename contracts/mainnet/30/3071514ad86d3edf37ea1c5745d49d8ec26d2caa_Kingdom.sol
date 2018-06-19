contract Kingdom {
    
    struct City {
        mapping(uint => uint) resources; //food, wood, stone, iron, gold, ... special
        mapping(uint => mapping(uint => uint)) map;
        mapping(uint => uint) resourceFactors; //population, food, wood, stone, iron, gold, woodWork, mason, blacksmith, goldforge, spirit, prestige
        uint populationNeeded;
        uint mapX;      //expansion of the map along the x diagonal
        uint mapY;      //expansion of the map along the y diagonal
        uint lastClaimResources;                //when did the user last claim his resources  
        mapping(uint => uint) lastClaimItems;   //when did the user last claim his special items
        bool initiatet;
    }
    
    struct Building {
        uint resource0;
        uint resource1;
        uint price0;
        uint price1;
        uint resourceIndex;
        uint resourceAmount;
    }
    
    address public owner;
    address public king;
    uint    public kingSpirit;
    address public queen;
    uint    public queenPrestige;
    uint    public totalCities;
    uint    public buildings_total;
    uint    public sell_id;
    
    mapping(address => mapping(uint => uint)) marketplacePrices;
    mapping(address => mapping(uint => uint)) marketplaceID;
        
    mapping(address => City) kingdoms;      //users kingdoms
    mapping(uint => Building) buildings;    //list of possible buildings
    
    
    //Constructor
    function Kingdom () public {
        owner           = msg.sender;
        king            = msg.sender;
        kingSpirit      = 0;
        queen           = msg.sender;
        queenPrestige   = 0;
        totalCities     = 0;
        buildings_total = 0;
        sell_id         = 0;
    }
            
/*  0  population
    1  food
    2  wood
    3  stone
    4  iron
    5  gold
    6  woodWork
    7  mason
    8  blacksmith
    9  goldforge
    10 spirit
    11 prestige */
            
    //Create buildings list
    function initBuilding(uint r0, uint r1, uint p0, uint p1, uint m, uint a) public {
        require(msg.sender == owner);
        //resource0, resource1, price0, price1, mapTo, mapAmount
        buildings[buildings_total]   = Building(r0,  r1,  p0,  p1,  m,   a); //grass
        buildings_total += 1;
       /*[0,  0,   0,  0,  0,  0], //grass
         [0,  1,   1,  1,  0,  20], //house
         [0,  1,   1,  1,  1,  1], //farm
         [1,  2,   1,  1,  2,  2], //lumbermill
         [1,  3,   2,  1,  3,  1], //stonemine
         [2,  3,   2,  1,  4,  1], //ironmine
         [4,  1,   1,  2,  5,  1], //goldmine
         [1,  3,   2,  2,  6,  1], //woodshop
         [2,  3,   2,  3,  7,  1], //masonry
         [3,  4,   3,  2,  8,  1], //blacksmith
         [4,  1,   2,  4,  9,  1], //goldforge
         [2,  17,  2,  1,  10, 1], //church
         [3,  9,   3,  1,  10, 2], //doctor
         [1,  5,   4,  1,  10, 4], //gentlemens club
         [3,  13,  3,  1,  10, 1], //inn
         [4,  18,  4,  2,  10, 2], //theater
         [2,  14,  5,  2,  10, 4], //concerthall
         [4,  6,   4,  2,  10, 1], //bathhouse
         [1,  10,  5,  2,  10, 2], //baker
         [3,  11,  6,  3,  10, 4], //museum
         [4,  7,   5,  3,  10, 1], //barber
         [1,  19,  6,  3,  10, 2], //tailor
         [2,  15,  7,  3,  10, 4], //arena
         [2,  12,  6,  1,  11, 1], //monument
         [3,  8,   7,  1,  11, 2], //park
         [2,  20,  8,  1,  11, 4], //plaza
         [1,  16, 10,  1,  11, 8] //castle */
    }
    //log resources
    
    event Resources(address sender, uint food, uint wood, uint stone, uint iron, uint gold);
    
    function logResources() public {
        Resources(  msg.sender,
                    kingdoms[msg.sender].resources[0],
                    kingdoms[msg.sender].resources[1],
                    kingdoms[msg.sender].resources[2],
                    kingdoms[msg.sender].resources[3],
                    kingdoms[msg.sender].resources[4]);
    }
    
    function newLeader() public {
        if(kingdoms[msg.sender].resourceFactors[10] > kingSpirit){
            kingSpirit = kingdoms[msg.sender].resourceFactors[10];
            king = msg.sender;
            NewLeader(msg.sender, kingSpirit, 0);
        }
        //try to claim the smaller throne
        if(kingdoms[msg.sender].resourceFactors[11] > queenPrestige){
            queenPrestige = kingdoms[msg.sender].resourceFactors[11];
            queen = msg.sender;
            NewLeader(msg.sender, queenPrestige, 1);
        }
    }
    
    //initiate user when first visiting
    function initiateUser() public {
        if(!kingdoms[msg.sender].initiatet){
            kingdoms[msg.sender].initiatet = true;
            kingdoms[msg.sender].resources[0] = 5;
            kingdoms[msg.sender].resources[1] = 5;
            kingdoms[msg.sender].resources[2] = 5;
            kingdoms[msg.sender].resources[3] = 5;
            kingdoms[msg.sender].resources[4] = 5;
            kingdoms[msg.sender].mapX = 6;
            kingdoms[msg.sender].mapY = 6;
            totalCities += 1;
            logResources();
        }
    }
    
    //log building creating for ease of reading
    event BuildAt(address sender, uint xpos, uint ypos, uint building);
    event NewLeader(address sender, uint spirit, uint Ltype);
    
    //build building at location (posx,posy)
    function buildAt(uint xpos, uint ypos, uint building) public {
        require(kingdoms[msg.sender].resources[buildings[building].resource0] >= buildings[building].price0
        &&      kingdoms[msg.sender].resources[buildings[building].resource1] >= buildings[building].price1
        &&      kingdoms[msg.sender].mapX > xpos
        &&      kingdoms[msg.sender].mapY > ypos
        &&      (kingdoms[msg.sender].populationNeeded <= kingdoms[msg.sender].resourceFactors[0] || building == 1)
        &&      building > 0 && building <= buildings_total
        &&      kingdoms[msg.sender].map[xpos][ypos] == 0);
        
        kingdoms[msg.sender].populationNeeded += 5;
        kingdoms[msg.sender].map[xpos][ypos] = building;
        kingdoms[msg.sender].resourceFactors[buildings[building].resourceIndex] += buildings[building].resourceAmount;
        
        kingdoms[msg.sender].resources[buildings[building].resource0] -= buildings[building].price0;
        kingdoms[msg.sender].resources[buildings[building].resource1] -= buildings[building].price1;
        
        //try to claim the throne
        newLeader();
        BuildAt(msg.sender, xpos, ypos, building);
        logResources();
    }
    
    //log when a user expands their map
    event ExpandX(address sender);
    event ExpandY(address sender);
    
    //expand map in direction x
    function expandX() public payable{
        assert(msg.value >= 300000000000000*(kingdoms[msg.sender].mapY));
        owner.transfer(msg.value);
        kingdoms[msg.sender].mapX += 1;
        ExpandX(msg.sender);
    }
    
    //expand map in direction Y
    function expandY() public payable{
        assert(msg.value >= 300000000000000*(kingdoms[msg.sender].mapX));
        owner.transfer(msg.value);
        kingdoms[msg.sender].mapY += 1;
        ExpandY(msg.sender);
    }
    
    
    //claim resources
    function claimBasicResources() public {
        //can claim every 2 hours - basic resources
        assert(now >= kingdoms[msg.sender].lastClaimResources + 1 * 1 hours);
        kingdoms[msg.sender].resources[0] += kingdoms[msg.sender].resourceFactors[1];
        kingdoms[msg.sender].resources[1] += kingdoms[msg.sender].resourceFactors[2];
        kingdoms[msg.sender].resources[2] += kingdoms[msg.sender].resourceFactors[3];
        kingdoms[msg.sender].resources[3] += kingdoms[msg.sender].resourceFactors[4];
        kingdoms[msg.sender].resources[4] += kingdoms[msg.sender].resourceFactors[5];
        kingdoms[msg.sender].lastClaimResources = now;
        logResources();
    }
    
    //log item clain
    event Items(address sender, uint item);
    function claimSpecialResource(uint shopIndex) public {
        //can claim every 5 hours - special items
        assert(now >= kingdoms[msg.sender].lastClaimItems[shopIndex] + 3 * 1 hours
        &&     shopIndex > 5
        &&     shopIndex < 10);
        for (uint item = 0; item < kingdoms[msg.sender].resourceFactors[shopIndex]; item++){
            //get pseudo random number
            uint select = ((now-(item+shopIndex))%13);
            uint finalI = 0;
            //award the item to player
            if(select < 6){
                finalI = ((shopIndex-6)*4)+5;   //
            }
            else if(select < 10){
                finalI = ((shopIndex-6)*4)+6;   //
            }
            else if(select < 12){
                finalI = ((shopIndex-6)*4)+7;   //
            }
            else {
                finalI = ((shopIndex-6)*4)+8;   //
            }
            kingdoms[msg.sender].resources[finalI] += 1;
            Items(msg.sender, finalI);
        }
        kingdoms[msg.sender].lastClaimItems[shopIndex] = now;
    }
    
    event SellItem (address sender, uint item, uint price, uint sell_id);
    
    function sellItem(uint item, uint price) public {
        assert( item >= 0
        &&      item <= 27
        &&      marketplacePrices[msg.sender][item] == 0
        &&      price > 0
        &&      kingdoms[msg.sender].resources[item] > 0);
        
        marketplacePrices[msg.sender][item] = price;
        marketplaceID[msg.sender][item] = sell_id;
        
        SellItem(msg.sender, item, price, sell_id);
        sell_id += 1;
        logResources();
    }
    
    event BuyItem (address buyer, uint item, uint sell_id);
    
    function buyItem (address seller, uint item) public payable {
        assert( msg.value >= marketplacePrices[seller][item]
                && marketplacePrices[seller][item] > 0
        );
        
        kingdoms[msg.sender].resources[item] += 1; 
        uint cut = msg.value/100;
        owner.transfer(cut*3);
        king.transfer(cut);
        queen.transfer(cut);
        seller.transfer(msg.value-(cut*5));
        marketplacePrices[seller][item] = 0;
        BuyItem (msg.sender, item, marketplaceID[seller][item]);
        logResources();
    }
    
    function buySpecialBuilding (uint xpos, uint ypos, uint building) public payable {
        require(kingdoms[msg.sender].mapX >= xpos
        &&      kingdoms[msg.sender].mapY >= ypos
        &&      ((msg.value >= 100000000000000000 && building == 97) || (msg.value >= 1000000000000000000 && building == 98) || (msg.value >= 5000000000000000000 && building == 99))
        &&      kingdoms[msg.sender].map[xpos][ypos] == 0);
        
        kingdoms[msg.sender].map[xpos][ypos] = building;
        
        if (building == 97){
            kingdoms[msg.sender].resourceFactors[10] += 8;
        }
        if (building == 98){
            kingdoms[msg.sender].resourceFactors[11] += 8;
        }
        if (building == 99){
            kingdoms[msg.sender].resourceFactors[11] += 16;
        }
        owner.transfer(msg.value);
        BuildAt(msg.sender, xpos, ypos, building);
        //try to claim the throne
        newLeader();
        
    }

}