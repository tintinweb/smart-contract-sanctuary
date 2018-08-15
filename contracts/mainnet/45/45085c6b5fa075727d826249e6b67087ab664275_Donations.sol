pragma solidity ^0.4.24;

contract ERC20Interface {
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _value) external;
}

contract Donations {
    struct Project
    {
        uint16 Id;
        uint256 Target;
        uint256 Current;
    }
    mapping(uint16 => Project) public projects;
    address owner;
    uint8 public projectsCount;
    
    address queen;
    address joker;
    address knight;
    address paladin;

    ERC20Interface horseToken;
    address horseTokenAddress = 0x5B0751713b2527d7f002c0c4e2a37e1219610A6B;
    
    uint8 jokerDivs = 50;
    uint8 knightDivs = 30;
    uint8 paladinDivs = 10;
    
    uint256 private toDistribute;
    uint256 private toDistributeHorse;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesHorse;
   
    constructor(address _queen, address _joker, address _knight, address _paladin) public {
        owner = msg.sender;
        queen = _queen;
        joker = _joker;
        knight = _knight;
        paladin = _paladin;

        horseToken = ERC20Interface(horseTokenAddress);
    }
 /*   
    function changeAddressQueen(address newAddr) external {
        require(msg.sender == queen,"wrong role");
        _transferCeo(newAddr);
        queen = newAddr;
    }
    function changeAddressJoker(address newAddr) external {
        require(msg.sender == joker,"wrong role");
        _transferCeo(newAddr);
        joker = newAddr;
    }
    function changeAddressKnight(address newAddr) external {
        require(msg.sender == knight,"wrong role");
        _transferCeo(newAddr);
        knight = newAddr;
    }
    function changeAddressPaladin(address newAddr) external {
        require(msg.sender == paladin,"wrong role");
        _transferCeo(newAddr);
        paladin = newAddr;
    }
*/    
    function addProject(uint256 target) external
    onlyOwner()
    returns (uint16) {
        uint16 newid = uint16(projectsCount);
        projectsCount = projectsCount + 1;
        Project storage proj = projects[newid];
        proj.Id = newid;
        proj.Target = target;
        return newid;
    }
    
    function donateToProject(uint16 id) external payable {
        require(id < projectsCount,"project doesnt exist");
        require(msg.value > 0,"non null donations only");
        projects[id].Current = projects[id].Current + msg.value;
        toDistribute = toDistribute + msg.value;
    }
    
    function () external payable {
       //fallback function just accept the funds
    }
    
    function withdraw() external {
        //check for pure transfer ETH and HORSe donations
        _distributeRest();
        if(toDistribute > 0)
            _distribute();
        if(toDistributeHorse > 0)
            _distributeHorse();
        if(_balances[msg.sender] > 0) {
            msg.sender.transfer(_balances[msg.sender]);
            _balances[msg.sender] = 0;
        }

        if(_balancesHorse[msg.sender] > 0) {
            horseToken.transfer(msg.sender,_balancesHorse[msg.sender]);
            _balancesHorse[msg.sender] = 0;
        }
    }
    
    function checkBalance() external view
    onlyCeo() returns (uint256,uint256) {
        return (_balances[msg.sender],_balancesHorse[msg.sender]);
    }

    function _distributeRest() internal {
        int rest = int(address(this).balance)
        - int(_balances[joker]) 
        - int(_balances[knight]) 
        - int(_balances[paladin]) 
        - int(_balances[queen]) 
        - int(toDistribute);
        if(rest > 0) {
            toDistribute = toDistribute + uint256(rest);
        }

        uint256 ownedHorse = horseToken.balanceOf(address(this));
        if(ownedHorse > 0) {
            int restHorse = int(ownedHorse)
            - int(_balancesHorse[joker]) 
            - int(_balancesHorse[knight]) 
            - int(_balancesHorse[paladin]) 
            - int(_balancesHorse[queen]) 
            - int(toDistributeHorse);

            if(restHorse > 0) {
                toDistributeHorse = toDistributeHorse + uint256(restHorse);
            }
        }
    }
    
    function _distribute() private {
        uint256 parts = toDistribute / 100;
        uint256 jokerDue = parts * 50;
        uint256 knightDue = parts * 30;
        uint256 paladinDue = parts * 10;

        _balances[joker] = _balances[joker] + jokerDue;
        _balances[knight] = _balances[knight] + knightDue;
        _balances[paladin] = _balances[paladin] + paladinDue;
        _balances[queen] = _balances[queen] + (toDistribute - jokerDue - knightDue - paladinDue);
        
        toDistribute = 0;
    }

    function _distributeHorse() private {
        uint256 parts = toDistributeHorse / 100;
        uint256 jokerDue = parts * 50;
        uint256 knightDue = parts * 30;
        uint256 paladinDue = parts * 10;

        _balancesHorse[joker] = _balancesHorse[joker] + jokerDue;
        _balancesHorse[knight] = _balancesHorse[knight] + knightDue;
        _balancesHorse[paladin] = _balancesHorse[paladin] + paladinDue;
        _balancesHorse[queen] = _balancesHorse[queen] + (toDistributeHorse - jokerDue - knightDue - paladinDue);

        toDistributeHorse = 0;
    }
 /*   
    function _transferCeo(address newAddr) internal
    unique(newAddr)
    {
        require(newAddr != address(0),"address is 0");

        _balances[newAddr] = _balances[msg.sender];
        _balances[msg.sender] = 0;

        _balancesHorse[newAddr] = _balancesHorse[msg.sender];
        _balancesHorse[msg.sender] = 0;
    }
 */   
    function _isCeo(address addr) internal view returns (bool) {
        return ((addr == queen) || (addr == joker) || (addr == knight) || (addr == paladin));
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    
    modifier onlyCeo() {
        require(_isCeo(msg.sender), "not ceo");
        _;
    }
    
    modifier unique(address newAddr) {
        require(!_isCeo(newAddr),"not unique");
        _;
    }
}