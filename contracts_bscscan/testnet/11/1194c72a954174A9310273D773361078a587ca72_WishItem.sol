pragma solidity ^0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
} 
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom( address from, address to, uint256 tokenId) external;
    function transferFrom( address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data ) external;

    struct HeroesInfo {uint256 heroesNumber; string name; string race; string class; string tier; string tierBasic;}
    function getHeroesNumber(uint256 _tokenId) external view returns (HeroesInfo memory);
    function safeMint(address _to, uint256 _tokenId) external;
    function burn(address _from, uint256 _tokenId) external;
    function addHeroesNumber(uint256 _tokenId, uint256 _heroesNumber, string memory name, string memory race, string memory class, string memory tier, string memory tierBasic) external;
    function editTier(uint256 tokenId, string memory _tier) external;
    function deleteHeroesNumber(uint256 tokenId) external;
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { return interfaceId == type(IERC165).interfaceId; }
}
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view override returns (bool) { return _roles[role].members[account]; }
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) { return _roles[role].adminRole; }
    function grantRole(bytes32 role, address account) public virtual override { 
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual override {
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }
    function renounceRole(bytes32 role, address account) public virtual override
    {
        require( account == _msgSender(), "AccessControl: can only renounce roles for self" );
        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual { _grantRole(role, account); }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }
    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }
    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
interface BlackList { 
	function getTokenId(address _token, uint256 tokenId) external view returns(uint256);
}
contract WishItem is AccessControl {
    using SafeMath for uint; 
    IERC721 public heroesNFT;
    address hereosNFTAddress;
    BlackList public blackList;
    address payable revenueAddress = payable(0x592D08eb6445366F6673F39D35fB833c4963208c);
    constructor( address _heroesNft, address _blackList) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		heroesNFT = IERC721(_heroesNft); // Token Hero Assets
        blackList = BlackList(_blackList);
        hereosNFTAddress = _heroesNft;
	}
    event ListItem(
        address owner,
        address nftContract,
        uint256 id,
        uint256 numberHero,
        uint256 numberTier,
        uint256 amount,
        uint256 timeListItem
    );
    event Cancel(
        uint256 id,
        uint256 timeCancel
    );
    event ChangeAmount(
        uint256 id,
        uint256 amount,
        uint256 timeChangeAmount
    );
    event MatchTransaction(
        address buyer,
        address owner,
        uint256 tokenId,
        uint256 id,
        uint256 timeMatch
    );
    struct ItemInfo {
        address owner;
        uint256 numberHero;
        uint256 numberTier;
        uint256 amount;
        uint256 status; // 1 : list , 2 : cancel, 3 : match
    }
    mapping(uint256 => ItemInfo) public itemInfo;
    mapping(uint256 => uint256) public tierNumber;
    mapping(uint256 => uint256) public raceNumber;
    mapping(uint256 => mapping(uint256 => uint256)) public minAmount; // tierNumber -> raceNumber -> minAmount;
    mapping(uint256 => bool) public idItem;
    mapping(uint256 => mapping(uint256 => uint256[])) public amountHero; // numberhero -> tier -> array
    mapping(uint256 => mapping(uint256 => uint256[])) public idHero; // numberhero -> tier -> array
    uint256 public MaxTier; // 1 .. 15 => Common , Rare , Rare*, Epic, Epic*, Legendery, Legendery*, Immortal, Immortal*, Ultimate, Ultimate 1, Ultimate 2, Ultimate 3, Ultimate 4, Ultimate 5
    uint256 public fee = 0;
    string[] public heroTier;
    function addHeroTier(string[] memory _heroTier) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i =0; i < _heroTier.length ; i++) {
            heroTier.push(_heroTier[i]);
        }
        MaxTier = _heroTier.length;
    }
    function setBlackList(address _blacklist) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        blackList = BlackList(_blacklist);
    }
    function changeFee(uint256 _fee) public { // 1000 %
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee > 0, "fee > 0");
        fee = _fee;
    }
    function changeRevenueAddress(address _receive) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_receive != address(0));
        revenueAddress = payable(_receive);
    }
    function addMinAmount(uint256[] memory _amount, uint256[] memory _amountSpecial) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_amount.length == _amountSpecial.length, 'False input');
        for(uint256 i = 1; i<= _amount.length; i++){
            require(_amount[i-1] >= 0 && _amountSpecial[i-1] >= 0, "amount > 0");
            minAmount[i][1] = _amountSpecial[i-1];
            minAmount[i][2] = _amount[i-1];
        }
    }
    function addHero(uint256[] memory heroId, uint256[] memory tier, uint256[] memory _raceNumber)public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(heroId.length == tier.length && heroId.length == _raceNumber.length, 'False input');
        for(uint256 i = 0; i < heroId.length ; i ++) {
           tierNumber[heroId[i]] = tier[i];
           raceNumber[heroId[i]] = _raceNumber[i];
        }
    } 

    function listItem(uint256 id, uint256 _numberHero, uint256 _numberTier, uint256 _amount) external payable {
        require(!idItem[id], "idItem used");
        // require(_amount >= MinAmount, "Price must be greater than minimum");
        require(tierNumber[_numberHero] != 0 && _numberTier <= MaxTier && tierNumber[_numberHero] <= _numberTier, "Tier is incorrect");
        if(tierNumber[_numberHero] == 1){
            require(_numberTier < 6, "Tier common max level");
        }
        uint256 numberRace = raceNumber[_numberHero];
        require(_amount >= minAmount[_numberTier][numberRace],"Price must be greater than minimum");
        itemInfo[id] = ItemInfo(msg.sender, _numberHero, _numberTier, _amount, 1);
        // heroesToken.safeTransferFrom(msg.sender, address(this), _amount);
        require(msg.value == _amount,"Please deposit more BNB");
        amountHero[_numberHero][_numberTier].push(_amount);
        idHero[_numberHero][_numberTier].push(id);
        idItem[id] = true; 
        emit ListItem(
            msg.sender,
            address(heroesNFT),
            id,
            _numberHero,
            _numberTier,
            _amount,
            block.timestamp
        );
    }
    function cancelList(uint256 id) external payable {
        require(itemInfo[id].owner == msg.sender, "You cannot delete this Item");
        require(itemInfo[id].status == 1, "Item not found");
        itemInfo[id].status = 2;
        payable(msg.sender).transfer(itemInfo[id].amount);
        // heroesToken.transfer(msg.sender, itemInfo[id].amount);
        uint256 heroesNumber = itemInfo[id].numberHero;
        uint256 tier = itemInfo[id].numberTier;
        uint256[] memory listIdHero = idHero[heroesNumber][tier];
        (uint256 elementMaxId, bool finId) = getIdHero(listIdHero, id);
        require(finId, "Can't find id");
        amountHero[heroesNumber][tier][elementMaxId] = amountHero[heroesNumber][tier][listIdHero.length-1];
        idHero[heroesNumber][tier][elementMaxId] = idHero[heroesNumber][tier][listIdHero.length-1];
        amountHero[heroesNumber][tier].pop();
        idHero[heroesNumber][tier].pop();
        // remove in list amount, id
        emit Cancel(
            id,
            block.timestamp
        ); 
    }
    function getListHero(uint256 _numberHero, uint256 _tier) public view returns(uint256[] memory id, uint256[] memory amount){
        id = idHero[_numberHero][_tier];
        amount = amountHero[_numberHero][_tier];
    }
    function getIdHero(uint256[] memory listHeroId, uint256 id) public pure returns(uint256, bool){
        uint256 numberMax = 0;
        bool findId = false;
        for(uint256 i = 0; i <  listHeroId.length; i++){
            if(listHeroId[i] == id) {
                numberMax = i;
                findId = true;
            } 
        }
        return (numberMax, findId);
    }
    // change amount in amountHero
    function changeAmount(uint256 id, uint256 amount) external payable {
        require(itemInfo[id].owner == msg.sender, "You cannot delete this Item");
        require(itemInfo[id].status == 1, "Item not found");
        // require(amount >= MinAmount, "Price must be greater than minimum");
        uint256 numberHero = itemInfo[id].numberHero;
        uint256 numberTier = itemInfo[id].numberTier;
        uint256 numberRace = raceNumber[numberHero];
        require(amount >= minAmount[numberTier][numberRace],"Price must be greater than minimum");
        if(itemInfo[id].amount > amount){
            payable(msg.sender).transfer(itemInfo[id].amount.sub(amount));
            // heroesToken.transfer(address(msg.sender), itemInfo[id].amount.sub(amount));
        }
        if(itemInfo[id].amount < amount){
            require(msg.value == amount.sub(itemInfo[id].amount),"Please deposit more BNB");
            // heroesToken.safeTransferFrom(msg.sender, address(this), amount.sub(itemInfo[id].amount));
        }
        itemInfo[id].amount = amount;
        uint256[] memory listIdHero = idHero[numberHero][numberTier];
        (uint256 elementMaxId, bool finId) = getIdHero(listIdHero, id);
        require(finId, "Can't find id");
        amountHero[numberHero][numberTier][elementMaxId] = amount;
        emit ChangeAmount(
            id,
            amount,
            block.timestamp
        );
    }

    function matchTransactionWithId(uint256 id, uint256 tokenId) public {
        require(itemInfo[id].status == 1, "Item not found");
        require(heroesNFT.ownerOf(tokenId) == msg.sender, "You is not owner of tokenid now");
        require(itemInfo[id].owner != msg.sender, "You are buying yours");
        require(itemInfo[id].numberHero == heroesNFT.getHeroesNumber(tokenId).heroesNumber, "Hero does not match");
        uint256 tier = queryNumberTier(heroesNFT.getHeroesNumber(tokenId).tier);
        require(itemInfo[id].numberTier == tier, "Tier does not match");
        require(blackList.getTokenId(hereosNFTAddress, tokenId) < block.timestamp, "TokenId in blacklist");
        uint256 heroesNumber = itemInfo[id].numberHero;
        uint256[] memory arrayHero = amountHero[heroesNumber][tier];
        uint256 elementMax = getMaxValue(arrayHero);
        require(id == idHero[heroesNumber][tier][elementMax], "ID not match");
        heroesNFT.safeTransferFrom(msg.sender, itemInfo[id].owner, tokenId);
        uint256 feeMarket = itemInfo[id].amount.mul(fee).div(1000);
        uint256 amountOfRecipient = itemInfo[id].amount.sub(feeMarket);
        // heroesToken.transfer(itemInfo[id].owner, amountOfRecipient);
        // heroesToken.transfer(revenueAddress, feeMarket);
        payable(itemInfo[id].owner).transfer(amountOfRecipient);
        revenueAddress.transfer(feeMarket);
        itemInfo[id].status = 3;
        amountHero[heroesNumber][tier][elementMax] = amountHero[heroesNumber][tier][arrayHero.length-1];
        idHero[heroesNumber][tier][elementMax] = idHero[heroesNumber][tier][arrayHero.length-1];
        amountHero[heroesNumber][tier].pop();
        idHero[heroesNumber][tier].pop();
        emit MatchTransaction(
            msg.sender,
            itemInfo[id].owner,
            tokenId,
            id, 
            block.timestamp
        );
    }

    function matchTransaction(uint256 tokenId) public {
        require(heroesNFT.ownerOf(tokenId) == msg.sender, "You is not owner of tokenid now");
        uint256 heroesNumber = heroesNFT.getHeroesNumber(tokenId).heroesNumber;
        uint256 tier = queryNumberTier(heroesNFT.getHeroesNumber(tokenId).tier);
        uint256[] memory arrayHero = amountHero[heroesNumber][tier];
        require(arrayHero.length > 0, "Can't find list wish itemm");
        require(blackList.getTokenId(hereosNFTAddress, tokenId) < block.timestamp, "TokenId in blacklist");
        uint256 elementMax = getMaxValue(arrayHero);
        uint256 id = idHero[heroesNumber][tier][elementMax];
        require(itemInfo[id].status == 1, "Item not found");
        require(itemInfo[id].owner != msg.sender, "You are buying yours");
        heroesNFT.safeTransferFrom(msg.sender, itemInfo[id].owner, tokenId);
        uint256 feeMarket = itemInfo[id].amount.mul(fee).div(1000);
        uint256 amountOfRecipient = itemInfo[id].amount.sub(feeMarket);
        payable(itemInfo[id].owner).transfer(amountOfRecipient);
        revenueAddress.transfer(feeMarket);
        // heroesToken.transfer(itemInfo[id].owner, amountOfRecipient);
        // heroesToken.transfer(revenueAddress, feeMraket);
        itemInfo[id].status = 3;
        amountHero[heroesNumber][tier][elementMax] = amountHero[heroesNumber][tier][arrayHero.length-1];
        idHero[heroesNumber][tier][elementMax] = idHero[heroesNumber][tier][arrayHero.length-1];
        amountHero[heroesNumber][tier].pop();
        idHero[heroesNumber][tier].pop();
        emit MatchTransaction(
            msg.sender,
            itemInfo[id].owner,
            tokenId,
            id, 
            block.timestamp
        );
    }
    function getMaxValue(uint256[] memory arrayHero) public pure returns(uint256) {
        uint256 largest = 0; 
        uint256 numberMax = 0;
        for(uint256 i = 0; i <  arrayHero.length; i++){
            if(arrayHero[i] > largest) {
                largest = arrayHero[i]; 
                numberMax = i;
            } 
        }
        return numberMax;
    }
    function queryNumberTier(string memory _tier) public view returns(uint256) {
        uint256 result = 100;
        for(uint256 i = 0 ; i < heroTier.length ; i ++) {
            if( keccak256(bytes(heroTier[i])) == keccak256(bytes(_tier)) ) {
                result = i + 1;
            }
        }
        return result;
    }

}