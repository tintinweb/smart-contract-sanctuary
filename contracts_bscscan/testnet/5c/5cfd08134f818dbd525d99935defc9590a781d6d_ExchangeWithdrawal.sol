/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

pragma solidity ^0.5.17;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address payable public  _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(),'EUW: Not Owner');
        _;
    }
    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address  payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0),'EUW: Invalid Address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract IBEP20 {
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public returns (bool success);
}
contract ExchangeUserWallet {
    mapping (address => bool) public _admin;
    address payable public _owner;
    event AuthorisedModule(address indexed module, bool value);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    constructor (address _module, address payable owner) public {
        _admin[address(_module)] = true; // ALready our deployed admin smart contract
        _admin[address(owner)] = true;
        _owner = owner;
        emit AuthorisedModule(address(_module), _admin[address(_module)]);
    }
 
    function()
        payable
        external
    {
        _owner.transfer(msg.value);
    }
    function updateAdmin(address adminAddress,bool status) public authorize {
        _admin[adminAddress] = status;
    }
    
    function updateOwner(address payable newOwner) public authorize {
        _owner = newOwner;
    }
    modifier authorize() {
        if(_admin[msg.sender]) {
            _;
        }
        else {
            revert('EUW: Not Authorized');
        }
    }
    function withdrawalBEP20 (
        address contractAddress,
        address receiverAddress,
        uint256  contractAmountToWithdrawal
    )
        public
        authorize
        returns (bool)
    {
        require(IBEP20(contractAddress).balanceOf(address(this)) >= contractAmountToWithdrawal,'EUW: Insufficient Balance');
        require(IBEP20(contractAddress).transfer(receiverAddress,contractAmountToWithdrawal),'EUW: Transfer Error');
        return true;
    }
    
    function withdrawalBNB(address payable receiverAddress, uint256  bnbAmountToWithdrawal) public authorize returns(bool) {
        receiverAddress.transfer(bnbAmountToWithdrawal);
    }
}

contract ExchangeWithdrawal is Ownable {
    mapping (address => bool) public _admin;
    //platform specific constant required to generate address
    string constant ACCOUNT_SALT_MSG_PREFIX = "SALTV1.0";
    // The hash of the wallet contract
    bytes32 public contractCodeHash;
    // The code of the wallet contract
    bytes public contractCode;
    event WalletCreated(address indexed _wallet, address indexed _owner);
    constructor () public {
        //get the contract code for dynamically deploying new wallets
        contractCode = type(ExchangeUserWallet).creationCode;
        
        contractCode = abi.encodePacked(contractCode, abi.encode(address(this), msg.sender));
        //create contract code hash
        contractCodeHash = keccak256(contractCode);
    }
    function updateAdmin(address adminAddress,bool status) public authorize {
        _admin[adminAddress] = status;
    }
    modifier authorize() {
            if(isOwner() || _admin[msg.sender]) {
                _;
            }
            else {
                revert('EUW: Not Authorized');
            }
        }
        
    //withdrawal from smart contract when limit increase in case of multiple contract need to withdraw
    function withdrawalBNB (
        address payable[] memory allUserContractAddressesAsSender,
        uint256  contractAmountToWithdrawal)
        public authorize
    {
        uint256 amountWithdrawalSuccessfully = 0;
        for(uint8 i = 0;i < allUserContractAddressesAsSender.length; i++)
        {
            if(amountWithdrawalSuccessfully >= contractAmountToWithdrawal){
                break;
            }
            uint256 balanceOfContract = address(allUserContractAddressesAsSender[i]).balance;
            uint256 amountToWithdrawalNow = 0;
            if((amountWithdrawalSuccessfully + balanceOfContract) <= contractAmountToWithdrawal) {
                amountToWithdrawalNow = balanceOfContract;
                amountWithdrawalSuccessfully += balanceOfContract;
            }else{
                amountToWithdrawalNow = (contractAmountToWithdrawal - amountWithdrawalSuccessfully);
                amountWithdrawalSuccessfully += amountToWithdrawalNow;
            }
            ExchangeUserWallet(allUserContractAddressesAsSender[i]).withdrawalBNB(_owner,amountToWithdrawalNow);
        }
    }
    //withdrawal from smart contract when limit increase in case of multiple contract need to withdraw
    function withdrawalBEP20 (
        address payable bep20Contract,
        address payable[] memory allUserContractAddressesAsSender,
        uint256  contractAmountToWithdrawal)
        public authorize
    {
        uint256 amountWithdrawalSuccessfully = 0;
        for(uint8 i = 0;i < allUserContractAddressesAsSender.length; i++)
        {
            if(amountWithdrawalSuccessfully >= contractAmountToWithdrawal){
                break;
            }
            uint256 balanceOfContract = IBEP20(bep20Contract).balanceOf(allUserContractAddressesAsSender[i]);
            uint256 amountToWithdrawalNow = 0;
            if((amountWithdrawalSuccessfully + balanceOfContract) <= contractAmountToWithdrawal) {
                amountToWithdrawalNow = balanceOfContract;
                amountWithdrawalSuccessfully += balanceOfContract;
            }else{
                amountToWithdrawalNow = (contractAmountToWithdrawal - amountWithdrawalSuccessfully);
                amountWithdrawalSuccessfully += amountToWithdrawalNow;
            }
            ExchangeUserWallet(allUserContractAddressesAsSender[i]).withdrawalBEP20(bep20Contract,_owner,amountToWithdrawalNow);
        }
    }
    
    
      function deploy(bytes32 salt) external authorize returns (address) {
        address payable addr;
        bytes memory bytecode  = contractCode;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        emit WalletCreated(addr, msg.sender);
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }
    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt) public view returns (address) {
        return computeAddress(salt, contractCodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}