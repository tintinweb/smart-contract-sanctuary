//SourceUnit: UltimateChainSale.sol

pragma solidity 0.5.14;

contract Context {
    function msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Ownable is Context {
    address payable private _owner;
    address payable private _admin;
    constructor () internal {
        _owner = msgSender();
        _admin = msgSender();
    }
    function owner() public view returns (address payable) {
        return _owner;
    }
    function admin() public view returns (address payable) {
        return _admin;
    }
    modifier onlyOwner() {
        require(_owner == msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyAdmin() {
        require(_admin == msgSender(), "Ownable: caller is not the admin");
        _;
    }
    function transferOwnership(address payable newOwner) external onlyOwner {
        _owner = newOwner;
    }
    function transferAdminship(address payable newAdmin) external onlyAdmin {
        _admin = newAdmin;
    }
}
contract UltimateChainSale is Ownable {
    ITRC20 private token;
    uint40 private startsale;
    uint256 private startprice;
    bool private salesEnabled;
    uint256 private totalbuyers;
    uint256 private totalpurchases;
    uint256 private airdropcycle;
    uint8[9] private refbonuses;
    uint8[3] private fees;
    uint256[] private airdrops;
    struct User {
        address payable upline;
        uint256 purchases;
        uint256 structure;
        uint256 income;
        uint256 airdropcycle;
    }
    mapping (address => User) private buyers;
    event Upline(address indexed buyer, address indexed upline);
    event Sale(address indexed payee, uint256 amount);
    event Airdrop(address indexed user, uint256 token);
    constructor (ITRC20 newToken) public {
        token = newToken;
        refbonuses = [34,17,10,10,10,5,5,5,4];
        fees = [62,38,43];
        startprice = 7e6;
        startsale = uint40(block.timestamp);
        salesEnabled = true;
    }
    function setToken(address newToken) external onlyOwner {
        token = ITRC20(newToken);
    }
    function toogleSale() external onlyOwner {
        salesEnabled = salesEnabled == true?false:true;
    }
    function purchase(address upline) external payable canSale {
        address _to = msgSender();
        User storage u = buyers[_to];
        bool _newref = false;
        if(u.purchases == 0) {
            if(u.upline == address(0) && _to != upline && buyers[upline].purchases > 0){
                u.upline = address(uint160(upline));
                _newref = true;
                emit Upline(_to, upline);
            }
            u.airdropcycle = airdropcycle;
            totalbuyers++;
        }
        uint256 _val = msg.value;
        uint256 _currentprice = getCurrentPrice();
        require(_val >= _currentprice*70, "UltimateChainSale: error min 70 buy token");
        uint256 _amount = _val*1e6/_currentprice;
        buyers[_to].purchases += _amount;
        totalpurchases += _amount;
        if(totalpurchases >= 15e11*(airdropcycle+1)){
            airdropcycle = airdrops.push(1e11/totalbuyers);
        }
        address payable _up = u.upline;
        if(_up != address(0)){
            uint256 _ref_val = _val*fees[2]/100;
            for(uint8 i = 0; i < 9; i++){
                if(_up == address(0)) break;
                if(_newref == true) buyers[_up].structure++;
                buyers[_up].income += _ref_val*refbonuses[i]/100;
                _up.transfer(_ref_val*refbonuses[i]/100);
                _up = buyers[_up].upline;
            }
        }
        uint256 _ico = address(this).balance;
        owner().transfer(_ico*fees[0]/100);
        admin().transfer(_ico*fees[1]/100);
        token.transfer(_to, _amount);
        emit Sale(_to, _amount);
    }
    function airdrop() external {
        address _to = msgSender();
        User storage u = buyers[_to];
        require(u.purchases > 0, "UltimateChainSale: first need to buy tokens");
        require(u.airdropcycle < airdropcycle,'UltimateChainSale: airdrop is not available yet');
        uint256 _amount = airdrops[u.airdropcycle];
        token.transfer(_to, _amount);
        u.airdropcycle++;
        emit Airdrop(_to, _amount);
    }
    function getCurrentPeriod() public view returns(uint256 currentperiod) {
        return (block.timestamp - startsale) / (60*60*24);
    }
    function getCurrentPrice() public view returns(uint256 price) {
        return 7e6 + 7e6 * 28 * getCurrentPeriod() / 10000;
    }
    function getContractInfo() external view returns(
        uint40 _startsale,
        uint256 _currentprice,
        bool _salesenabled,
        uint256 _totalbuyers,
        uint256 _totalpurchases,
        uint256 _period,
        uint256 _airdropcycle
    ){
        return (
        startsale,
        getCurrentPrice(),
        salesEnabled,
        totalbuyers,
        totalpurchases,
        getCurrentPeriod(),
        airdropcycle
        );
    }
    function getBuyerInfo(address addr) external view returns(
        address _upline,
        uint256 _structure,
        uint256 _purchases,
        uint256 _income,
        uint256 _airdropcycle
    ){
        User storage u = buyers[addr];
        return (
        u.upline,
        u.structure,
        u.purchases,
        u.income,
        u.airdropcycle
        );
    }
    function getAirdrop(uint256 indx) external view returns(uint256 _airdrops){
        require(indx < airdropcycle,"UltimateChainSale: This airdrop hasn't happened yet");
        return airdrops[indx];
    }
    function recoverTRC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        ITRC20(tokenAddress).transfer(owner(), tokenAmount);
    }
    function recoverTRX(uint256 amount) public onlyOwner {
        owner().transfer(amount);
    }
    modifier canSale() {
        require(salesEnabled == true, "UltimateChainSale: token sale closed");
        _;
    }
}