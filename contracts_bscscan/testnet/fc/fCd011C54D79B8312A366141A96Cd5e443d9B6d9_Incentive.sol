/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

interface IPledgeContract {
    function queryNodeIndex(address _nodeAddr) external view returns(uint256);

}

interface IIncentive {
    function withdrawToken(address[2] calldata addrs,uint256[2] calldata uints,uint8[] calldata vs,bytes32[] calldata rssMetadata) external;
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
contract  Incentive  is Initializable,Ownable,IIncentive {
    IPledgeContract public pledgeContract;
    address public executor;
    bool public pause;
    mapping(address => uint256) public nonce;
    mapping(address => uint256) public withdrawSums;
    mapping(address => mapping(uint256 => uint256)) public withdrawAmounts;
    event UpdateExecutor(address _executor);
    event WithdrawToken(address indexed _userAddr, uint256 _nonce, uint256 _amount);


    struct Data {
        address userAddr;
        address contractAddr;
        uint256 amount;
        uint256 expiration;
    }

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "IncentiveContracts: caller is not the executor");
        _;
    }

    modifier onlyGuard() {
        require(!pause, "IncentiveContracts: The system is suspended");
        _;
    }

    function init(address _executor, address _pledgeContract) external initializer{
        __Ownable_init_unchained();
        __Incentive_init_unchained(_executor,_pledgeContract);
    }
    
    function __Incentive_init_unchained(address _executor, address _pledgeContract) internal initializer{
        executor = _executor;
        pledgeContract = IPledgeContract(_pledgeContract);
    }

    receive() payable external{

    }

    function  updatePause(bool _sta) external onlyExecutor{
        pause = _sta;
    }

    function  updateExecutor(address _executor) external onlyOwner{
        executor = _executor;
        emit UpdateExecutor(_executor);
    }

    function  modifierPledgeContract(address _pledgeContract) public onlyExecutor{
        pledgeContract = IPledgeContract(_pledgeContract);
    }
    
    /**
    * @notice A method to the user withdraw revenue.
    * The extracted proceeds are signed by at least 6 PAGERANK servers, in order to withdraw successfully
    */
    function withdrawToken(
        address[2] calldata addrs,
        uint256[2] calldata uints,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    )
    external
    override
    onlyGuard
    {
        require(addrs[0] == msg.sender, "IncentiveContracts: Signing users are not the same as trading users");
        require( block.timestamp<= uints[1], "IncentiveContracts: The transaction exceeded the time limit");
        uint256 len = vs.length;
        uint256 counter;
        uint256 _nonce = nonce[addrs[0]]++;
        require(len*2 == rssMetadata.length, "IncentiveContracts: Signature parameter length mismatch");
        bytes32 digest = _calcDataHash(Data( addrs[0], addrs[1], uints[0], uints[1]), _nonce);
        for (uint256 i = 0; i < len; i++) {
            bool result = _verifySign(
                digest,
                Sig(vs[i], rssMetadata[i*2], rssMetadata[i*2+1])
            );
            if (result){
                counter++;
            }
            if (counter >= 6){
                break;
            }
        }
        require(
            counter >= 6,
            "The number of signed accounts has not reached the minimum threshold of six"
        );
        withdrawSums[addrs[0]] +=  uints[0];
        withdrawAmounts[addrs[0]][_nonce] =  uints[0];
        IERC20  token = IERC20(addrs[1]);
        require(
            token.transfer(addrs[0],uints[0]),
            "Token transfer failed"
        );
        emit WithdrawToken(addrs[0], _nonce, uints[0]);
    }

    function _verifySign(bytes32 _digest,Sig memory _sig) internal view returns (bool)  {
        address _accessAccount = ecrecover(_digest, _sig.v, _sig.r, _sig.s);
        uint256 _nodeRank = pledgeContract.queryNodeIndex(_accessAccount);
        return _nodeRank < 12 && _nodeRank > 0;
    }

    function _calcDataHash(Data memory _data, uint256 _nonce) internal pure returns (bytes32)  {
        string memory msgData = strConcat(toString(_data.userAddr),toString(_data.contractAddr), uint2str( _data.amount), uint2str(_data.expiration),uint2str(_nonce));
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes memory dataBytes= bytes(msgData);
        uint256 len = dataBytes.length;
        bytes32 digest = keccak256(abi.encodePacked(prefix, bytes(uint2str(len)),msgData));
        return digest;
    }

    function uint2str(uint i) internal pure returns (string memory c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] =bytes1(uint8(48 + i % 10));
            i /= 10;
        }
        c = string(bstr);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function toString(address account) internal pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}