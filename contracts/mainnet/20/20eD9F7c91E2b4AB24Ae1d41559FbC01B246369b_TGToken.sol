/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.11;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract Ownable {
    address public owner;
    address public manager;
    uint private unlocked = 1;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "1000");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == owner || (manager != address(0) && msg.sender == manager), "1000");
        _;
    }

    function setManager(address user) external onlyOwner {
        manager = user;
    }

    modifier lock() {
        require(unlocked == 1, '1001');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, '1002');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, '1002');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, '1002');
    }
    
    function div(uint x,uint y) internal pure returns (uint z){
        if(x==0){
            return 0;
        }
        require(y == 0 || (z = x / y) > 0, '100');
    }
}

/**
1000:必须是管理员
1001:交易暂时锁定
1002:只允许矿工合约回调
1003:不接收ETH
1004:不能购买TGToken
1005:存量不足
1006:超出发行量
1007:不允许注册
1008:矿工合约无效
1009:签名无效
1010:已领取过的空投或奖励
3000:已停止兑换
3001:不允许增发
3002:不允许销毁
 */

contract BaseERC20 is IERC20,Ownable{
    using SafeMath for uint;
    string public name;
    string public symbol;
    string public desc = "";
    uint public constant decimals = 18;
    uint public totalSupply;
    uint public sellRatio = 0;
    uint public developTime;
    bool public allowMint = false;
    bool public allowBurn = false;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;


    constructor (
        string memory _name,string memory _symbol,uint _totalSupply,
        bool _allowMint, bool _allowBurn
    ) public {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply * 10 ** decimals;
        allowMint = _allowMint;
        allowBurn = _allowBurn;
        //solium-disable-next-line
        developTime = block.timestamp;
    }

    function _approve(address from, address spender, uint value) internal {
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function _transferFrom(address spender, address from, address to, uint value) internal {
        if (allowance[from][spender] != uint(-1)) {
            allowance[from][spender] = allowance[from][spender].sub(value);
        }
        _transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        _transferFrom(msg.sender, from, to, value);
        return true;
    }

    function transferBatch(address[] calldata addresses, uint[] calldata values) external payable returns (bool success){
        require(
            addresses.length > 0 &&
            (addresses.length == values.length || values.length == 1),
            '1005'
        );

        uint256 total = 0;
        uint256 length = addresses.length;
        if(values.length == 1){
            total = values[0].mul(length);
        }else{
            for(uint256 i = 0 ; i < length; i++){
                total = total.add(values[i]);
            }
        }

        require(msg.value > 0 ? msg.value >= total : balanceOf[msg.sender] >= total,"1002");

        for(uint i = 0 ; i < addresses.length; i++){
            address to = addresses[i];
            uint amount = (values.length == 1) ? values[0] : values[i];
            if(msg.value > 0){
                address(uint160(to)).transfer(amount);
            }else{
                _transfer(msg.sender, to, amount);
            }
        }

        return true;
    }

    function setSellRatio(uint ratio) external onlyOwner{
        sellRatio = ratio;
    }

}

contract UserToken is BaseERC20{
    using SafeMath for uint;
    event Buy(address indexed from,uint value,uint tokens);
    event Mint(address indexed from,uint amount,uint total,uint balance);
    event Burn(address indexed from,uint amount,uint total,uint balance);
    constructor(
        address _owner,string memory _name,string memory _symbol,uint _totalSupply,
        bool _allowMint, bool _allowBurn
    ) BaseERC20(_name,_symbol,_totalSupply,_allowMint,_allowBurn) public {
        owner = _owner;
        balanceOf[owner] = totalSupply;
    }

    function () external payable {
        buy();
    }
    function buy() public payable{
        require(sellRatio > 0, '3000');
        uint tokens = msg.value.mul(sellRatio);
        _transfer(owner,msg.sender,tokens);
        address(uint160(owner)).transfer(msg.value);
        emit Buy(msg.sender, msg.value, tokens);
    }
    function mint(address account, uint amount) external onlyOwner{
        require(allowMint,"3001");
        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Mint(account,amount,totalSupply,balanceOf[account]);
    }

    function burn(uint amount) external{
        require(allowBurn,"3002");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Burn(msg.sender, amount, totalSupply,balanceOf[msg.sender]);
    }

    function setDesc(string calldata _desc) external onlyOwner{
        desc = _desc;
    }

    function viewSummary() external view returns (
        string memory _name,string memory _symbol,uint _decimals,uint _totalSupply,
        bool _allowMint, bool _allowBurn,uint _sellRatio,uint _developTime,string memory _desc
    ){
        return (name,symbol,decimals,totalSupply,allowMint,allowBurn,sellRatio,developTime,desc);
    }
}

contract TGToken is BaseERC20 {
    using SafeMath for uint;
    address public lastMintContract;
    mapping(address => bool) mintContracts;
    uint public limitSupply;
    uint sellQuantity = 0;
    mapping(address => UserToken) public factorys;
    bytes32 DOMAIN_SEPARATOR;
    bytes32 constant AIRDROP_TYPE = keccak256('AirDrop(address receiver,address issuer,uint256 value,uint256 nonce)');
    bytes32 public constant PERMIT_TYPE = keccak256('Permit(address owner,address spender,uint256 value)');
    mapping(address=>mapping(uint=>uint)) public airDropNonces;
    event Buy(address indexed from,uint value,uint tokens);
    event MintCallback(address indexed from,uint amount,uint total,uint balance);
    event RedeemCallback(address indexed from,uint amount,uint total,uint balance);
    event CreateToken(address indexed contractAddress,address userAddress);

    constructor () BaseERC20('Telegram Token','TG',3 * 10 ** 6,false,false) public {
        limitSupply = 3 ether * 10 ** 8;
        sellRatio = 10000;
        balanceOf[msg.sender] = totalSupply;
        mintContracts[msg.sender] = true;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256('Telegram Token'),
                keccak256("1"),
                1,
                address(this)
            )
        );
    }

    modifier onlyMintContract() {
        require(mintContracts[msg.sender], '1002');
        _;
    }

    function () external payable {
        revert('1003');
    }

    function buy() public payable{
        require(sellRatio > 0, '1004');
        uint tokens = msg.value.mul(sellRatio);
        require(sellQuantity >= tokens, '1005');
        sellQuantity = sellQuantity.sub(tokens);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        address(uint160(owner)).transfer(msg.value);
        emit Buy(msg.sender, msg.value, tokens);
    }

    function mint(address miner,uint tokens,uint additional) external onlyMintContract returns (bool success){
        uint increment = tokens.add(additional);
        uint _totalSupply = totalSupply.add(increment);
        require(_totalSupply <= limitSupply, '1006');

        balanceOf[miner] = balanceOf[miner].add(tokens);
        if(additional > 0){
            balanceOf[owner] = balanceOf[owner].add(additional);
        }
        totalSupply = _totalSupply;
        emit MintCallback(miner,tokens,totalSupply,balanceOf[miner]);
        return true;
    }

    function redeem(address miner,uint tokens) external onlyMintContract returns (bool success){
        balanceOf[miner] = balanceOf[miner].sub(tokens);
        totalSupply = totalSupply.sub(tokens);
        emit RedeemCallback(miner, tokens, totalSupply,balanceOf[miner]);
        return true;
    }

    function addMintContract(address mint_contract) external onlyOwner{
        require(mint_contract != address(0), '1008');
        mintContracts[mint_contract] = true;
        lastMintContract = mint_contract;
    }

    function setSellQuantity(uint quantity) external onlyOwner{
        if(quantity == 0){
            totalSupply = totalSupply.sub(sellQuantity);
            sellQuantity = 0;
        }else{
            sellQuantity = sellQuantity.add(quantity);
            totalSupply = totalSupply.add(quantity);
            require(totalSupply<=limitSupply,"1006");
        }
    }

    function viewSummary() external view
        returns (uint balance,uint _totalSupply,uint _limitSupply,
        uint _sellRatio,uint _sellQuantity,address _lastMintContract)
    {
        return (address(this).balance,totalSupply,limitSupply,sellRatio,sellQuantity,lastMintContract);
    }

    function permit(address owner, address spender, uint value, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPE, owner, spender, value))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, '1009');
        _approve(owner, spender, value);
    }

    function airDrop(address receiver,address issuer,uint256 value,uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(AIRDROP_TYPE, receiver,issuer, value,nonce))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == issuer, '1009');
        require(airDropNonces[receiver][nonce]==0,'1010');
        airDropNonces[receiver][nonce] = value;
        _transfer(issuer, receiver, value);
    }

    function factory(
        string calldata _name,string calldata _symbol,uint _totalSupply,
        bool _allowMint, bool _allowBurn
    ) external {
        factorys[msg.sender] = new UserToken(msg.sender,_name,_symbol,_totalSupply,_allowMint,_allowBurn);
        emit CreateToken(address(factorys[msg.sender]),msg.sender);
    }

}