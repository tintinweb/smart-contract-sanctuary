pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract Payeth is Ownable {
    // 議論点
    // stringtとbytes32はどう使い分けるべきか
    // eventをemitする必要はあるのか
    // eventの引数にindexedはつけたほうが良いのか
    // creatorBalanceはpublicで良いのか
    mapping (address => mapping (bytes32 =>uint)) public paidAmount;
    mapping (address => uint) public balances;
    uint8 public feeRate;

    event PayForUrl(address _from, address _creator, string _url, uint amount);
    event Withdraw(address _from, uint amount);
    constructor (uint8 _feeRate){
        feeRate = _feeRate;
    }
    function payForUrl(address _creator,string _url) public payable {
        uint fee = (msg.value * feeRate) / 100; 
        balances[owner()] += fee;
        balances[_creator] += msg.value - fee;
        paidAmount[msg.sender][keccak256(_url)] += msg.value;
        emit PayForUrl(msg.sender,_creator,_url,msg.value);
    }
    function setFeeRate (uint8 _feeRate)public onlyOwner{
        require(_feeRate < feeRate, "Cannot raise fee rate");
        feeRate = _feeRate;
    }
    function withdraw() public{
        uint balance = balances[msg.sender];
        require(balance > 0, "Balance must be greater than zero");
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
        emit Withdraw(msg.sender, balance);
    }
}