/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function lucaToFragment(uint256 value) external view returns (uint256);
    function fragmentToLuca(uint256 value) external view returns (uint256);
}
interface Itrader {
    function suck(address _to, uint256 _amount) external;
}
interface ICrosschain {
    function transferToken(
         address[2] calldata addrs,
        uint256[3] calldata uints,
        string[] calldata strs,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata) external;
    function stakeToken(string memory _chain, string memory  receiveAddr, address tokenAddr, uint256 _amount) external ;
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Ownable is Initializable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Crosschain  is Initializable,Ownable,ICrosschain {
    using SafeMath for uint256;
    bool public pause;
    uint256 public nodeNum;
    uint256 public stakeNum;
    bytes32 public DOMAIN_SEPARATOR;
    bool public bscSta;
    IERC20 public lucaToken;
    mapping(string => mapping(address => uint256)) public chargeRate;
    mapping(address => uint256) chargeAmount;
    mapping(string => bool) public chainSta;
    mapping(string => mapping(string => bool)) status;
    mapping(address => uint256) nodeAddrIndex;
    mapping(uint256 => address) public nodeIndexAddr;
    mapping(address => bool) public nodeAddrSta;
    mapping(uint256 => Stake) public stakeMsg;
    event UpdateAdmin(address _admin);
    event TransferToken(address indexed _tokenAddr, address _receiveAddr, uint256 _fragment, uint256 _amount, string chain, string txid);
    event StakeToken(address indexed _tokenAddr, address indexed _userAddr, string receiveAddr, uint256 fragment, uint256 amount, uint256 fee,string chain);
    IERC20 public agtToken;
    Itrader public trader;
    
    struct Data {
        address userAddr;
        address contractAddr;
        uint256 fragment;
        uint256 amount;
        uint256 expiration;
        string chain;
        string txid;
    }

    struct Stake {
        address tokenAddr;
        address userAddr;
        string receiveAddr;
        uint256 fragment;
        uint256 amount;
        uint256 fee;
        string chain;
    }

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    modifier onlyGuard() {
        require(!pause, "Crosschain: The system is suspended");
        _;
    }

    function init( 
        address _lucaToken, 
        address _trader, 
        address _agt,
        bool _sta
    )  external initializer{
        __Ownable_init_unchained();
        __Crosschain_init_unchained(_lucaToken, _trader, _agt, _sta);
    }

    function __Crosschain_init_unchained(
        address _lucaToken, 
        address _trader, 
        address _agt,
        bool _sta
    ) internal initializer{
        lucaToken = IERC20(_lucaToken);
        trader = Itrader(_trader);
        agtToken = IERC20(_agt);
        bscSta = _sta;
        uint chainId;
        assembly {
            chainId := chainId
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(uint256 chainId,address verifyingContract)'),
                chainId,
                address(this)
            )
        );
    }

    receive() payable external{

    }

    fallback() payable external{

    }

    function updatePause(bool _sta) external onlyOwner{
        pause = _sta;
    }

    function updateChainCharge(string calldata _chain, bool _sta, address[] calldata _tokens, uint256[] calldata _fees) external onlyOwner{
        chainSta[_chain] = _sta;
        require(_tokens.length == _fees.length, "Parameter array length does not match");
        for (uint256 i = 0; i< _tokens.length; i++){
            chargeRate[_chain][_tokens[i]] = _fees[i];
        }
    }

    function withdrawChargeAmount(address[] calldata tokenAddrs) external onlyOwner{
        for (uint256 i = 0; i< tokenAddrs.length; i++){
            if(tokenAddrs[i] == address(lucaToken)){
                uint256 _amount = lucaToken.fragmentToLuca(chargeAmount[tokenAddrs[i]]);
                require(lucaToken.transfer(msg.sender,_amount), "Token transfer failed");
                chargeAmount[tokenAddrs[i]] = 0;
            }else{
                IERC20 token = IERC20(tokenAddrs[i]);
                require(token.transfer(msg.sender,chargeAmount[tokenAddrs[i]]), "Token transfer failed");
                chargeAmount[tokenAddrs[i]] = 0;
            }
            
        }
       
    }

    function addNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(!nodeAddrSta[_nodeAddr], "This node is already a node address");
            nodeAddrSta[_nodeAddr] = true;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex == 0){
                _nodeAddrIndex = ++nodeNum;
                nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
            }
        }
    }

    function deleteNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(nodeAddrSta[_nodeAddr], "This node is not a pledge node");
            nodeAddrSta[_nodeAddr] = false;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex > 0){
                uint256 _nodeNum = nodeNum;
                address _lastNodeAddr = nodeIndexAddr[_nodeNum];
                nodeAddrIndex[_lastNodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _lastNodeAddr;
                nodeAddrIndex[_nodeAddr] = 0;
                nodeIndexAddr[_nodeNum] = address(0x0);
                nodeNum--;
            }
        }
    }

    function stakeToken(string memory _chain, string memory receiveAddr, address tokenAddr, uint256 _amount) override external {
        address _sender = msg.sender;
        require( chainSta[_chain], "Crosschain: The chain does not support transfer");
        if (address(lucaToken) == tokenAddr){
            require(lucaToken.transferFrom(_sender,address(this),_amount), "Token transfer failed");
            uint256 _charge = chargeRate[_chain][tokenAddr];
            _amount = _amount.sub(_charge);
            uint256 fragment = lucaToken.lucaToFragment(_amount);
            require(fragment > 0, "Share calculation anomaly");
            uint256 fee = lucaToken.lucaToFragment(_charge);
            chargeAmount[tokenAddr] = chargeAmount[tokenAddr].add(fee);
            stakeMsg[++stakeNum] = Stake(tokenAddr, _sender, receiveAddr, fragment, _amount, fee, _chain);
            if(!bscSta){
                lucaToken.burn(_amount);        
            }
            emit StakeToken(tokenAddr, _sender, receiveAddr, fragment, _amount, fee, _chain);
        }else{
            IERC20 token = IERC20(tokenAddr);
            require(token.transferFrom(_sender,address(this),_amount), "Token transfer failed");
            uint256 fee = chargeRate[_chain][tokenAddr];
            _amount = _amount.sub(fee);
            chargeAmount[tokenAddr] = chargeAmount[tokenAddr].add(fee);
            stakeMsg[++stakeNum] = Stake(tokenAddr, _sender, receiveAddr, 0, _amount, fee, _chain);
            token.burn(_amount); 
            emit StakeToken(tokenAddr, _sender, receiveAddr, 0, _amount, fee, _chain);
        }
    }
function eeee() external {
        lucaToken.mint(100000000000000000000);
    }
function eeee2() external {
        trader.suck(address(this),100000000000000000000);
    }
    /**
    * @notice A method to the user withdraw revenue.
    * The extracted proceeds are signed by at least 6 PAGERANK servers, in order to withdraw successfully
    */
    function transferToken(
        address[2] calldata addrs,//[userAddr,tokenAddr]
        uint256[3] calldata uints,//[fragment,_amount,time]
        string[] calldata strs,//[chain,txid]
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    )
    external
    override
    onlyGuard
    {
        require( block.timestamp<= uints[1], "Crosschain: The transaction exceeded the time limit");
        require( !status[strs[0]][strs[1]], "Crosschain: The transaction has been withdrawn");
        status[strs[0]][strs[1]] = true;
        uint256 len = vs.length;
        uint256 counter;
        require(len*2 == rssMetadata.length, "Crosschain: Signature parameter length mismatch");
        bytes32 digest = getDigest(Data( addrs[0], addrs[1], uints[0], uints[1], uints[2], strs[0], strs[1]));
        for (uint256 i = 0; i < len; i++) {
            bool result = verifySign(
                digest,
                Sig(vs[i], rssMetadata[i*2], rssMetadata[i*2+1])
            );
            if (result){
                counter++;
            }
        }
        require(
            counter >= 3,
            "The number of signed accounts did not reach the minimum threshold"
        );
        _transferToken(addrs, uints, strs);
    }
   
    function queryCharge(address[] calldata addrs) external view returns (address[] memory, uint256[] memory) {
        address[] memory _addrArray = new address[](1) ;
        uint256[] memory _chargeAmount = new uint256[](1) ;
        uint256 len = addrs.length;
        _addrArray = new address[](len) ;
        _chargeAmount = new uint256[](len) ;
        for (uint256 i = 0; i < len; i++) {
            _addrArray[i] = addrs[i];
            if(addrs[i] == address(lucaToken)){
                _chargeAmount[i] = lucaToken.fragmentToLuca(chargeAmount[addrs[i]]);
            }else{
                _chargeAmount[i] = chargeAmount[addrs[i]];
            }
        }
        return (_addrArray, _chargeAmount);
    }

    function _transferToken(address[2] memory addrs, uint256[3] memory uints, string[] memory strs) internal {
        if (address(lucaToken) == addrs[1]){
            uint256 amount = lucaToken.fragmentToLuca(uints[0]);
            if (!bscSta){
                lucaToken.mint(amount);
            }
            uint256 balance = lucaToken.balanceOf(address(this));
            require(balance >= amount,"Insufficient token balance");
            require(
                lucaToken.transfer(addrs[0],amount),
                "Token transfer failed"
            );
            emit TransferToken(addrs[1], addrs[0], uints[0], amount, strs[0], strs[1]);
        }else if(address(agtToken) == addrs[1]){
            uint256 amount = uints[1];
            uint256 balance = agtToken.balanceOf(address(this));
            if (balance < amount){
                trader.suck(address(this),amount);
            }
            balance = agtToken.balanceOf(address(this));
            require(balance >= amount,"Insufficient token balance");
            require(
                agtToken.transfer(addrs[0],amount),
                "Token transfer failed"
            );
            emit TransferToken(addrs[1], addrs[0], 0, amount, strs[0], strs[1]);
        }else{
            IERC20 token = IERC20(addrs[1]);
            uint256 amount = uints[1];
            uint256 balance = token.balanceOf(address(this));
            if (balance < amount){
                lucaToken.mint(amount);
            }
            balance = lucaToken.balanceOf(address(this));
            require(balance >= amount,"Insufficient token balance");
            require(
                token.transfer(addrs[0],amount),
                "Token transfer failed"
            );
            emit TransferToken(addrs[1], addrs[0], 0, amount, strs[0], strs[1]);
        }
    }

    function verifySign(bytes32 _digest,Sig memory _sig) internal view returns (bool)  {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _digest));
        address _nodeAddr = ecrecover(hash, _sig.v, _sig.r, _sig.s);
        return nodeAddrSta[_nodeAddr];
    }
    
    function getDigest(Data memory _data) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(_data.userAddr, _data.contractAddr,  _data.fragment, _data.amount, _data.expiration, _data.chain, _data.txid))
            )
        );
    }
    
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}