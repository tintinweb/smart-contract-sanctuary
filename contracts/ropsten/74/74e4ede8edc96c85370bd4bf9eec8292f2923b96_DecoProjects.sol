pragma solidity 0.4.25;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7f1b1e091a3f1e1410121d1e511c1012">[email&#160;protected]</a>
// released under Apache 2.0 licence
library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

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

contract DecoBaseProjectsMarketplace is Ownable {
    using SafeMath for uint256;

    // `DecoRelay` contract address.
    address public relayContractAddress;

    /**
     * @dev Payble fallback for reverting transactions of any incoming ETH.
     */
    function () public payable {
        require(msg.value == 0, "Blocking any incoming ETH.");
    }

    /**
     * @dev Set the new address of the `DecoRelay` contract.
     * @param _newAddress An address of the new contract.
     */
    function setRelayContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Relay address must not be 0x0.");
        relayContractAddress = _newAddress;
    }

    /**
     * @dev Allows to trasnfer any ERC20 tokens from the contract balance to owner&#39;s address.
     * @param _tokenAddress An `address` of an ERC20 token.
     * @param _tokens An `uint` tokens amount.
     * @return A `bool` operation result state.
     */
    function transferAnyERC20Token(
        address _tokenAddress,
        uint _tokens
    )
        public
        onlyOwner
        returns (bool success)
    {
        IERC20 token = IERC20(_tokenAddress);
        return token.transfer(owner(), _tokens);
    }
}


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/// @title Contract to store other contracts newest versions addresses and service information.
contract DecoRelay is DecoBaseProjectsMarketplace {
    address public projectsContractAddress;
    address public milestonesContractAddress;
    address public escrowFactoryContractAddress;
    address public arbitrationContractAddress;

    address public feesWithdrawalAddress;

    uint8 public shareFee;

    function setProjectsContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        projectsContractAddress = _newAddress;
    }

    function setMilestonesContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        milestonesContractAddress = _newAddress;
    }

    function setEscrowFactoryContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        escrowFactoryContractAddress = _newAddress;
    }

    function setArbitrationContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        arbitrationContractAddress = _newAddress;
    }

    function setFeesWithdrawalAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        feesWithdrawalAddress = _newAddress;
    }

    function setShareFee(uint8 _shareFee) external onlyOwner {
        require(_shareFee <= 100, "Deconet share fee must be less than 100%.");
        shareFee = _shareFee;
    }
}

/**
 * @title Escrow contract, every project deploys a clone and transfer ownership to the project client, so all
 *        funds not reserved to pay for a milestone can be safely moved in/out.
 */
contract DecoEscrow is DecoBaseProjectsMarketplace {
    using SafeMath for uint256;

    // Indicates if the current clone has been initialized.
    bool internal isInitialized;

    // Stores share fee that should apply on any successful distribution.
    uint8 public shareFee;

    // Authorized party for executing funds distribution operations.
    address public authorizedAddress;

    // State variable to track available ETH Escrow owner balance.
    // Anything that is not blocked or distributed in favor of any party can be withdrawn by the owner.
    uint public balance;

    // Mapping of available for withdrawal funds by the address.
    // Accounted amounts are excluded from the `balance`.
    mapping (address => uint) public withdrawalAllowanceForAddress;

    // Maps information about the amount of deposited ERC20 token to the token address.
    mapping(address => uint) public tokensBalance;

    /**
     * Mapping of ERC20 tokens amounts to token addresses that are available for withdrawal for a given address.
     * Accounted here amounts are excluded from the `tokensBalance`.
     */
    mapping(address => mapping(address => uint)) public tokensWithdrawalAllowanceForAddress;

    // ETH amount blocked in Escrow.
    // `balance` excludes this amount.
    uint public blockedBalance;

    // Mapping of the amount of ERC20 tokens to the the token address that are blocked in Escrow.
    // A token value in `tokensBalance` excludes stored here amount.
    mapping(address => uint) public blockedTokensBalance;

    // Logged when an operation with funds occurred.
    event FundsOperation (
        address indexed sender,
        address indexed target,
        address tokenAddress,
        uint amount,
        PaymentType paymentType,
        OperationType indexed operationType
    );

    // Logged when the given address authorization to distribute Escrow funds changed.
    event FundsDistributionAuthorization (
        address targetAddress,
        bool isAuthorized
    );

    // Accepted types of payments.
    enum PaymentType { Ether, Erc20 }

    // Possible operations with funds.
    enum OperationType { Receive, Send, Block, Unblock, Distribute }

    // Restrict function call to be originated from an address that was authorized to distribute funds.
    modifier onlyAuthorized() {
        require(authorizedAddress == msg.sender, "Only authorized addresses allowed.");
        _;
    }

    /**
     * @dev Default `payable` fallback to accept incoming ETH from any address.
     */
    function () public payable {
        deposit();
    }

    /**
     * @dev Initialize the Escrow clone with default values.
     * @param _newOwner An address of a new escrow owner.
     * @param _authorizedAddress An address that will be stored as authorized.
     */
    function initialize(
        address _newOwner,
        address _authorizedAddress,
        uint8 _shareFee,
        address _relayContractAddress
    )
        external
    {
        require(!isInitialized, "Only uninitialized contracts allowed.");
        isInitialized = true;
        authorizedAddress = _authorizedAddress;
        emit FundsDistributionAuthorization(_authorizedAddress, true);
        _transferOwnership(_newOwner);
        shareFee = _shareFee;
        relayContractAddress = _relayContractAddress;
    }

    /**
     * @dev Start transfering the given amount of the ERC20 tokens available by provided address.
     * @param _tokenAddress ERC20 token contract address.
     * @param _amount Amount to transfer from sender`s address.
     */
    function depositErc20(address _tokenAddress, uint _amount) external {
        require(_tokenAddress != address(0x0), "Token Address shouldn&#39;t be 0x0.");
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer operation should be successful."
        );
        tokensBalance[_tokenAddress] = tokensBalance[_tokenAddress].add(_amount);
        emit FundsOperation (
            msg.sender,
            address(this),
            _tokenAddress,
            _amount,
            PaymentType.Erc20,
            OperationType.Receive
        );
    }

    /**
     * @dev Withdraw the given amount of ETH to sender`s address if allowance or contract balance is sufficient.
     * @param _amount Amount to withdraw.
     */
    function withdraw(uint _amount) external {
        withdrawForAddress(msg.sender, _amount);
    }

    /**
     * @dev Withdraw the given amount of ERC20 token to sender`s address if allowance or contract balance is sufficient.
     * @param _tokenAddress ERC20 token address.
     * @param _amount Amount to withdraw.
     */
    function withdrawErc20(address _tokenAddress, uint _amount) external {
        withdrawErc20ForAddress(msg.sender, _tokenAddress, _amount);
    }

    /**
     * @dev Block funds for future use by authorized party stored in `authorizedAddress`.
     * @param _amount An uint of Wei to be blocked.
     */
    function blockFunds(uint _amount) external onlyAuthorized {
        require(_amount <= balance, "Amount to block should be less or equal than balance.");
        balance = balance.sub(_amount);
        blockedBalance = blockedBalance.add(_amount);
        emit FundsOperation (
            address(this),
            msg.sender,
            address(0x0),
            _amount,
            PaymentType.Ether,
            OperationType.Block
        );
    }

    /**
     * @dev Blocks ERC20 tokens funds for future use by authorized party listed in `authorizedAddress`.
     * @param _tokenAddress An address of ERC20 token.
     * @param _amount An uint of tokens to be blocked.
     */
    function blockTokenFunds(address _tokenAddress, uint _amount) external onlyAuthorized {
        uint accountedTokensBalance = tokensBalance[_tokenAddress];
        require(
            _amount <= accountedTokensBalance,
            "Tokens mount to block should be less or equal than balance."
        );
        tokensBalance[_tokenAddress] = accountedTokensBalance.sub(_amount);
        blockedTokensBalance[_tokenAddress] = blockedTokensBalance[_tokenAddress].add(_amount);
        emit FundsOperation (
            address(this),
            msg.sender,
            _tokenAddress,
            _amount,
            PaymentType.Erc20,
            OperationType.Block
        );
    }

    /**
     * @dev Distribute funds between contract`s balance and allowance for some address.
     *  Deposit may be returned back to the contract address, i.e. to the escrow owner.
     *  Or deposit may flow to the allowance for an address as a result of an evidence
     *  given by an authorized party about fullfilled obligations.
     *  **IMPORTANT** This operation includes fees deduction.
     * @param _destination Destination address for funds distribution.
     * @param _amount Amount to distribute in favor of a destination address.
     */
    function distributeFunds(
        address _destination,
        uint _amount
    )
        external
        onlyAuthorized
    {
        require(
            _amount <= blockedBalance,
            "Amount to distribute should be less or equal than blocked balance."
        );
        uint amount = _amount;
        if (shareFee > 0 && relayContractAddress != address(0x0)) {
            DecoRelay relayContract = DecoRelay(relayContractAddress);
            address feeDestination = relayContract.feesWithdrawalAddress();
            uint fee = amount.mul(shareFee).div(100);
            amount = amount.sub(fee);
            blockedBalance = blockedBalance.sub(fee);
            withdrawalAllowanceForAddress[feeDestination] =
                withdrawalAllowanceForAddress[feeDestination].add(fee);
            emit FundsOperation(
                msg.sender,
                feeDestination,
                address(0x0),
                fee,
                PaymentType.Ether,
                OperationType.Distribute
            );
        }
        if (_destination == owner()) {
            unblockFunds(amount);
            return;
        }
        blockedBalance = blockedBalance.sub(amount);
        withdrawalAllowanceForAddress[_destination] = withdrawalAllowanceForAddress[_destination].add(amount);
        emit FundsOperation(
            msg.sender,
            _destination,
            address(0x0),
            amount,
            PaymentType.Ether,
            OperationType.Distribute
        );
    }

    /**
     * @dev Distribute ERC20 token funds between contract`s balance and allowanc for some address.
     *  Deposit may be returned back to the contract address, i.e. to the escrow owner.
     *  Or deposit may flow to the allowance for an address as a result of an evidence
     *  given by authorized party about fullfilled obligations.
     *  **IMPORTANT** This operation includes fees deduction.
     * @param _destination Destination address for funds distribution.
     * @param _tokenAddress ERC20 Token address.
     * @param _amount Amount to distribute in favor of a destination address.
     */
    function distributeTokenFunds(
        address _destination,
        address _tokenAddress,
        uint _amount
    )
        external
        onlyAuthorized
    {
        require(
            _amount <= blockedTokensBalance[_tokenAddress],
            "Amount to distribute should be less or equal than blocked balance."
        );
        uint amount = _amount;
        if (shareFee > 0 && relayContractAddress != address(0x0)) {
            DecoRelay relayContract = DecoRelay(relayContractAddress);
            address feeDestination = relayContract.feesWithdrawalAddress();
            uint fee = amount.mul(shareFee).div(100);
            amount = amount.sub(fee);
            blockedTokensBalance[_tokenAddress] = blockedTokensBalance[_tokenAddress].sub(fee);
            uint allowance = tokensWithdrawalAllowanceForAddress[feeDestination][_tokenAddress];
            tokensWithdrawalAllowanceForAddress[feeDestination][_tokenAddress] = allowance.add(fee);
            emit FundsOperation(
                msg.sender,
                feeDestination,
                _tokenAddress,
                fee,
                PaymentType.Erc20,
                OperationType.Distribute
            );
        }
        if (_destination == owner()) {
            unblockTokenFunds(_tokenAddress, amount);
            return;
        }
        blockedTokensBalance[_tokenAddress] = blockedTokensBalance[_tokenAddress].sub(amount);
        uint allowanceForSender = tokensWithdrawalAllowanceForAddress[_destination][_tokenAddress];
        tokensWithdrawalAllowanceForAddress[_destination][_tokenAddress] = allowanceForSender.add(amount);
        emit FundsOperation(
            msg.sender,
            _destination,
            _tokenAddress,
            amount,
            PaymentType.Erc20,
            OperationType.Distribute
        );
    }

    /**
     * @dev Withdraws ETH amount from the contract&#39;s balance to the provided address.
     * @param _targetAddress An `address` for transfer ETH to.
     * @param _amount An `uint` amount to be transfered.
     */
    function withdrawForAddress(address _targetAddress, uint _amount) public {
        require(
            _amount <= address(this).balance,
            "Amount to withdraw should be less or equal than balance."
        );
        if (_targetAddress == owner()) {
            balance = balance.sub(_amount);
        } else {
            uint withdrawalAllowance = withdrawalAllowanceForAddress[_targetAddress];
            withdrawalAllowanceForAddress[_targetAddress] = withdrawalAllowance.sub(_amount);
        }
        _targetAddress.transfer(_amount);
        emit FundsOperation (
            address(this),
            _targetAddress,
            address(0x0),
            _amount,
            PaymentType.Ether,
            OperationType.Send
        );
    }

    /**
     * @dev Withdraws ERC20 token amount from the contract&#39;s balance to the provided address.
     * @param _targetAddress An `address` for transfer tokens to.
     * @param _tokenAddress An `address` of ERC20 token.
     * @param _amount An `uint` amount of ERC20 tokens to be transfered.
     */
    function withdrawErc20ForAddress(address _targetAddress, address _tokenAddress, uint _amount) public {
        IERC20 token = IERC20(_tokenAddress);
        require(
            _amount <= token.balanceOf(this),
            "Token amount to withdraw should be less or equal than balance."
        );
        if (_targetAddress == owner()) {
            tokensBalance[_tokenAddress] = tokensBalance[_tokenAddress].sub(_amount);
        } else {
            uint tokenWithdrawalAllowance = getTokenWithdrawalAllowance(_targetAddress, _tokenAddress);
            tokensWithdrawalAllowanceForAddress[_targetAddress][_tokenAddress] = tokenWithdrawalAllowance.sub(
                _amount
            );
        }
        token.transfer(_targetAddress, _amount);
        emit FundsOperation (
            address(this),
            _targetAddress,
            _tokenAddress,
            _amount,
            PaymentType.Erc20,
            OperationType.Send
        );
    }

    /**
     * @dev Returns allowance for withdrawing the given token for sender address.
     * @param _tokenAddress An address of ERC20 token.
     * @return An uint value of allowance.
     */
    function getTokenWithdrawalAllowance(address _account, address _tokenAddress) public view returns(uint) {
        return tokensWithdrawalAllowanceForAddress[_account][_tokenAddress];
    }

    /**
     * @dev Accept and account incoming deposit in contract state.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposited amount should be greater than 0.");
        balance = balance.add(msg.value);
        emit FundsOperation (
            msg.sender,
            address(this),
            address(0x0),
            msg.value,
            PaymentType.Ether,
            OperationType.Receive
        );
    }

    /**
     * @dev Unblock blocked funds and make them available to the contract owner.
     * @param _amount An uint of Wei to be unblocked.
     */
    function unblockFunds(uint _amount) public onlyAuthorized {
        require(
            _amount <= blockedBalance,
            "Amount to unblock should be less or equal than balance"
        );
        blockedBalance = blockedBalance.sub(_amount);
        balance = balance.add(_amount);
        emit FundsOperation (
            msg.sender,
            address(this),
            address(0x0),
            _amount,
            PaymentType.Ether,
            OperationType.Unblock
        );
    }

    /**
     * @dev Unblock blocked token funds and make them available to the contract owner.
     * @param _amount An uint of Wei to be unblocked.
     */
    function unblockTokenFunds(address _tokenAddress, uint _amount) public onlyAuthorized {
        uint accountedBlockedTokensAmount = blockedTokensBalance[_tokenAddress];
        require(
            _amount <= accountedBlockedTokensAmount,
            "Tokens amount to unblock should be less or equal than balance"
        );
        blockedTokensBalance[_tokenAddress] = accountedBlockedTokensAmount.sub(_amount);
        tokensBalance[_tokenAddress] = tokensBalance[_tokenAddress].add(_amount);
        emit FundsOperation (
            msg.sender,
            address(this),
            _tokenAddress,
            _amount,
            PaymentType.Erc20,
            OperationType.Unblock
        );
    }

    /**
     * @dev Override base contract logic to block this operation for Escrow contract.
     * @param _tokenAddress An `address` of an ERC20 token.
     * @param _tokens An `uint` tokens amount.
     * @return A `bool` operation result state.
     */
    function transferAnyERC20Token(
        address _tokenAddress,
        uint _tokens
    )
        public
        onlyOwner
        returns (bool success)
    {
        return false;
    }
}

contract CloneFactory {

  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[26 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
  }
}

/**
 * @title Utility contract that provides a way to execute cheap clone deployment of the DecoEscrow contract
 *        on chain.
 */
contract DecoEscrowFactory is DecoBaseProjectsMarketplace, CloneFactory {

    // Escrow master-contract address.
    address public libraryAddress;

    // Logged when a new Escrow clone is deployed to the chain.
    event EscrowCreated(address newEscrowAddress);

    /**
     * @dev Constructor for the contract.
     * @param _libraryAddress Escrow master-contract address.
     */
    constructor(address _libraryAddress) public {
        libraryAddress = _libraryAddress;
    }

    /**
     * @dev Updates library address with the given value.
     * @param _libraryAddress Address of a new base contract.
     */
    function setLibraryAddress(address _libraryAddress) external onlyOwner {
        require(libraryAddress != _libraryAddress);
        require(_libraryAddress != address(0x0));

        libraryAddress = _libraryAddress;
    }

    /**
     * @dev Create Escrow clone.
     * @param _ownerAddress An address of the Escrow contract owner.
     * @param _authorizedAddress An addresses that is going to be authorized in Escrow contract.
     */
    function createEscrow(
        address _ownerAddress,
        address _authorizedAddress
    )
        external
        returns(address)
    {
        address clone = createClone(libraryAddress);
        DecoRelay relay = DecoRelay(relayContractAddress);
        DecoEscrow(clone).initialize(
            _ownerAddress,
            _authorizedAddress,
            relay.shareFee(),
            relayContractAddress
        );
        emit EscrowCreated(clone);
        return clone;
    }
}

contract IDecoArbitrationTarget {

    /**
     * @dev Prepare arbitration target for a started dispute.
     * @param _idHash A `bytes32` hash of id.
     */
    function disputeStartedFreeze(bytes32 _idHash) public;

    /**
     * @dev React to an active dispute settlement with given parameters.
     * @param _idHash A `bytes32` hash of id.
     * @param _respondent An `address` of a respondent.
     * @param _respondentShare An `uint8` share for the respondent.
     * @param _initiator An `address` of a dispute initiator.
     * @param _initiatorShare An `uint8` share for the initiator.
     * @param _isInternal A `bool` indicating if dispute was settled by participants without an arbiter.
     * @param _arbiterWithdrawalAddress An `address` for sending out arbiter compensation.
     */
    function disputeSettledTerminate(
        bytes32 _idHash,
        address _respondent,
        uint8 _respondentShare,
        address _initiator,
        uint8 _initiatorShare,
        bool _isInternal,
        address _arbiterWithdrawalAddress
    )
        public;

    /**
     * @dev Check eligibility of a given address to perform operations.
     * @param _idHash A `bytes32` hash of id.
     * @param _addressToCheck An `address` to check.
     * @return A `bool` check status.
     */
    function checkEligibility(bytes32 _idHash, address _addressToCheck) public view returns(bool);

    /**
     * @dev Check if target is ready for a dispute.
     * @param _idHash A `bytes32` hash of id.
     * @return A `bool` check status.
     */
    function canStartDispute(bytes32 _idHash) public view returns(bool);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IDecoArbitration {

    /**
     * @dev Should be logged upon dispute start.
     */
    event LogStartedDispute(
        address indexed sender,
        bytes32 indexed idHash,
        uint timestamp,
        int respondentShareProposal
    );

    /**
     * @dev Should be logged upon proposal rejection.
     */
    event LogRejectedProposal(
        address indexed sender,
        bytes32 indexed idHash,
        uint timestamp,
        uint8 rejectedProposal
    );

    /**
     * @dev Should be logged upon dispute settlement.
     */
    event LogSettledDispute(
        address indexed sender,
        bytes32 indexed idHash,
        uint timestamp,
        uint8 respondentShare,
        uint8 initiatorShare
    );

    /**
     * @dev Should be logged when contract owner updates fees.
     */
    event LogFeesUpdated(
        uint timestamp,
        uint fixedFee,
        uint8 shareFee
    );

    /**
     * @dev Should be logged when time limit to accept/reject proposal for respondent is updated.
     */
    event LogProposalTimeLimitUpdated(
        uint timestamp,
        uint proposalActionTimeLimit
    );

    /**
     * @dev Should be logged when the withdrawal address for the contract owner changed.
     */
    event LogWithdrawalAddressChanged(
        uint timestamp,
        address newWithdrawalAddress
    );

    /**
     * @notice Start dispute for the given project.
     * @dev This call should log event and save dispute information and notify `IDecoArbitrationTarget` object
     *      about started dispute. Dipsute can be started only if target instance call of
     *      `canStartDispute` method confirms that state is valid. Also, txn sender and respondent addresses
     *      eligibility must be confirmed by arbitation target `checkEligibility` method call.
     * @param _idHash A `bytes32` hash of a project id.
     * @param _respondent An `address` of the second paty involved in the dispute.
     * @param _respondentShareProposal An `int` value indicating percentage of disputed funds
     *  proposed to the respondent. Valid values range is 0-100, different values are considered as &#39;No Proposal&#39;.
     *  When provided percentage is 100 then this dispute is processed automatically,
     *  and all funds are distributed in favor of the respondent.
     */
    function startDispute(bytes32 _idHash, address _respondent, int _respondentShareProposal) external;

    /**
     * @notice Accept active dispute proposal, sender should be the respondent.
     * @dev Respondent of a dispute can accept existing proposal and if proposal exists then `settleDispute`
     *      method should be called with proposal value. Time limit for respondent to accept/reject proposal
     *      must not be exceeded.
     * @param _idHash A `bytes32` hash of a project id.
     */
    function acceptProposal(bytes32 _idHash) external;

    /**
     * @notice Reject active dispute proposal and escalate dispute.
     * @dev Txn sender should be dispute&#39;s respondent. Dispute automatically gets escalated to this contract
     *      owner aka arbiter. Proposal must exist, otherwise this method should do nothing. When respondent
     *      rejects proposal then it should get removed and corresponding event should be logged.
     *      There should be a time limit for a respondent to reject a given proposal, and if it is overdue
     *      then arbiter should take on a dispute to settle it.
     * @param _idHash A `bytes32` hash of a project id.
     */
    function rejectProposal(bytes32 _idHash) external;

    /**
     * @notice Settle active dispute.
     * @dev Sender should be the current contract or its owner(arbiter). Action is possible only when there is no active
     *      proposal or time to accept the proposal is over. Sum of shares should be 100%. Should notify target
     *      instance about a dispute settlement via `disputeSettledTerminate` method call. Also corresponding
     *      event must be emitted.
     * @param _idHash A `bytes32` hash of a project id.
     * @param _respondentShare An `uint` percents of respondent share.
     * @param _initiatorShare An `uint` percents of initiator share.
     */
    function settleDispute(bytes32 _idHash, uint _respondentShare, uint _initiatorShare) external;

    /**
     * @return Retuns this arbitration contract withdrawal `address`.
     */
    function getWithdrawalAddress() external view returns(address);

    /**
     * @return The arbitration contract fixed `uint` fee and `uint8` share of all disputed funds fee.
     */
    function getFixedAndShareFees() external view returns(uint, uint8);

    /**
     * @return An `uint` time limit for accepting/rejecting a proposal by respondent.
     */
    function getTimeLimitForReplyOnProposal() external view returns(uint);

}



/// @title Contract for Project events and actions handling.
contract DecoProjects is DecoBaseProjectsMarketplace {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    // struct for project details
    struct Project {
        string agreementId;
        address client;
        address maker;
        address arbiter;
        address escrowContractAddress;
        uint startDate;
        uint endDate;
        uint8 milestoneStartWindow;
        uint8 feedbackWindow;
        uint8 milestonesCount;

        uint8 customerSatisfaction;
        uint8 makerSatisfaction;

        bool agreementsEncrypted;
    }

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Proposal {
        string agreementId;
        address arbiter;
    }

    bytes32 constant private EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant private PROPOSAL_TYPEHASH = keccak256(
        "Proposal(string agreementId,address arbiter)"
    );

    bytes32 private DOMAIN_SEPARATOR;

    // enumeration to describe possible project states for easier state changes reporting.
    enum ProjectState { Active, Completed, Terminated }

    // enumeration to describe possible satisfaction score types.
    enum ScoreType { CustomerSatisfaction, MakerSatisfaction }

    // Logged when a project state changes.
    event LogProjectStateUpdate (
        bytes32 indexed agreementHash,
        address updatedBy,
        uint timestamp,
        ProjectState state
    );

    // Logged when either party sets satisfaction score after the completion of a project.
    event LogProjectRated (
        bytes32 indexed agreementHash,
        address indexed ratedBy,
        address indexed ratingTarget,
        uint8 rating,
        uint timestamp
    );

    // maps the agreement`s unique hash to the project details.
    mapping (bytes32 => Project) public projects;

    // maps hashes of all maker&#39;s projects to the maker&#39;s address.
    mapping (address => bytes32[]) public makerProjects;

    // maps hashes of all client&#39;s projects to the client&#39;s address.
    mapping (address => bytes32[]) public clientProjects;

    // maps arbiter&#39;s fixed fee to a project.
    mapping (bytes32 => uint) public projectArbiterFixedFee;

    // maps arbiter&#39;s share fee to a project.
    mapping (bytes32 => uint8) public projectArbiterShareFee;

    // Modifier to restrict method to be called either by project`s owner or maker
    modifier eitherClientOrMaker(bytes32 _agreementHash) {
        Project memory project = projects[_agreementHash];
        require(
            project.client == msg.sender || project.maker == msg.sender,
            "Only project owner or maker can perform this operation."
        );
        _;
    }

    // Modifier to restrict method to be called either by project`s owner or maker
    modifier eitherClientOrMakerOrMilestoneContract(bytes32 _agreementHash) {
        Project memory project = projects[_agreementHash];
        DecoRelay relay = DecoRelay(relayContractAddress);
        require(
            project.client == msg.sender ||
            project.maker == msg.sender ||
            relay.milestonesContractAddress() == msg.sender,
            "Only project owner or maker can perform this operation."
        );
        _;
    }

    // Modifier to restrict method to be called by the milestones contract.
    modifier onlyMilestonesContract(bytes32 _agreementHash) {
        DecoRelay relay = DecoRelay(relayContractAddress);
        require(
            msg.sender == relay.milestonesContractAddress(),
            "Only milestones contract can perform this operation."
        );
        Project memory project = projects[_agreementHash];
        _;
    }

    constructor (uint256 _chainId) public {
        require(_chainId != 0, "You must specify a nonzero chainId");

        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "Deco.Network",
            version: "1",
            chainId: _chainId,
            verifyingContract: address(this)
        }));
    }

    /**
     * @dev Creates a new milestone-based project with pre-selected maker and owner. All parameters are required.
     * @param _agreementId A `string` unique id of the agreement document for that project.
     * @param _client An `address` of the project owner.
     * @param _arbiter An `address` of the referee to settle all escalated disputes between parties.
     * @param _maker An `address` of the project`s maker.
     * @param _makersSignature A `bytes` digital signature of the maker to proof the agreement acceptance.
     * @param _milestonesCount An `uint8` count of planned milestones for the project.
     * @param _milestoneStartWindow An `uint8` count of days project`s owner has to start the next milestone.
     *        If this time is exceeded then the maker can terminate the project.
     * @param _feedbackWindow An `uint8` time in days project`s owner has to provide feedback for the last milestone.
     *                        If that time is exceeded then maker can terminate the project and get paid for awaited
     *                        milestone.
     * @param _agreementEncrypted A `bool` flag indicating whether or not the agreement is encrypted.
     */
    function startProject(
        string _agreementId,
        address _client,
        address _arbiter,
        address _maker,
        bytes _makersSignature,
        uint8 _milestonesCount,
        uint8 _milestoneStartWindow,
        uint8 _feedbackWindow,
        bool _agreementEncrypted
    )
        external
    {
        require(msg.sender == _client, "Only the client can kick off the project.");
        require(_client != _maker, "Client can`t be a maker on her own project.");
        require(_arbiter != _maker && _arbiter != _client, "Arbiter must not be a client nor a maker.");

        require(
            isMakersSignatureValid(_maker, _makersSignature, _agreementId, _arbiter),
            "Maker should sign the hash of immutable agreement doc."
        );
        require(_milestonesCount >= 1 && _milestonesCount <= 24, "Milestones count is not in the allowed 1-24 range.");
        bytes32 hash = keccak256(_agreementId);
        require(projects[hash].client == address(0x0), "Project shouldn&#39;t exist yet.");

        saveCurrentArbitrationFees(_arbiter, hash);

        address newEscrowCloneAddress = deployEscrowClone(msg.sender);
        projects[hash] = Project(
            _agreementId,
            msg.sender,
            _maker,
            _arbiter,
            newEscrowCloneAddress,
            now,
            0, // end date is unknown yet
            _milestoneStartWindow,
            _feedbackWindow,
            _milestonesCount,
            0, // CSAT is 0 to indicate that it isn&#39;t set by maker yet
            0, // MSAT is 0 to indicate that it isn&#39;t set by client yet
            _agreementEncrypted
        );
        makerProjects[_maker].push(hash);
        clientProjects[_client].push(hash);
        emit LogProjectStateUpdate(hash, msg.sender, now, ProjectState.Active);
    }

    /**
     * @dev Terminate the project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     */
    function terminateProject(bytes32 _agreementHash)
        external
        eitherClientOrMakerOrMilestoneContract(_agreementHash)
    {
        Project storage project = projects[_agreementHash];
        require(project.client != address(0x0), "Only allowed for existing projects.");
        require(project.endDate == 0, "Only allowed for active projects.");
        address milestoneContractAddress = DecoRelay(relayContractAddress).milestonesContractAddress();
        if (msg.sender != milestoneContractAddress) {
            DecoMilestones milestonesContract = DecoMilestones(milestoneContractAddress);
            milestonesContract.terminateLastMilestone(_agreementHash, msg.sender);
        }

        project.endDate = now;
        emit LogProjectStateUpdate(_agreementHash, msg.sender, now, ProjectState.Terminated);
    }

    /**
     * @dev Complete the project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     */
    function completeProject(
        bytes32 _agreementHash
    )
        external
        onlyMilestonesContract(_agreementHash)
    {
        Project storage project = projects[_agreementHash];
        require(project.client != address(0x0), "Only allowed for existing projects.");
        require(project.endDate == 0, "Only allowed for active projects.");
        projects[_agreementHash].endDate = now;
        DecoMilestones milestonesContract = DecoMilestones(
            DecoRelay(relayContractAddress).milestonesContractAddress()
        );
        bool isLastMilestoneAccepted;
        uint8 milestoneNumber;
        (isLastMilestoneAccepted, milestoneNumber) = milestonesContract.isLastMilestoneAccepted(
            _agreementHash
        );
        require(
            milestoneNumber == projects[_agreementHash].milestonesCount,
            "The last milestone should be the last for that project."
        );
        require(isLastMilestoneAccepted, "Only allowed when all milestones are completed.");
        emit LogProjectStateUpdate(_agreementHash, msg.sender, now, ProjectState.Completed);
    }

    /**
     * @dev Rate the second party on the project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @param _rating An `uint8` satisfaction score of either client or maker.
              Min value is 1, max is 10.
     */
    function rateProjectSecondParty(
        bytes32 _agreementHash,
        uint8 _rating
    )
        external
        eitherClientOrMaker(_agreementHash)
    {
        require(_rating >= 1 && _rating <= 10, "Project rating should be in the range 1-10.");
        Project storage project = projects[_agreementHash];
        require(project.endDate != 0, "Only allowed for active projects.");
        address ratingTarget;
        if (msg.sender == project.client) {
            require(project.customerSatisfaction == 0, "CSAT is allowed to provide only once.");
            project.customerSatisfaction = _rating;
            ratingTarget = project.maker;
        } else {
            require(project.makerSatisfaction == 0, "MSAT is allowed to provide only once.");
            project.makerSatisfaction = _rating;
            ratingTarget = project.client;
        }
        emit LogProjectRated(_agreementHash, msg.sender, ratingTarget, _rating, now);
    }

    /**
     * @dev Query for getting the address of Escrow contract clone deployed for the given project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `address` of a clone.
     */
    function getProjectEscrowAddress(bytes32 _agreementHash) public view returns(address) {
        return projects[_agreementHash].escrowContractAddress;
    }

    /**
     * @dev Query for getting the address of a client for the given project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `address` of a client.
     */
    function getProjectClient(bytes32 _agreementHash) public view returns(address) {
        return projects[_agreementHash].client;
    }

    /**
     * @dev Query for getting the address of a maker for the given project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `address` of a maker.
     */
    function getProjectMaker(bytes32 _agreementHash) public view returns(address) {
        return projects[_agreementHash].maker;
    }

    /**
     * @dev Query for getting the address of an arbiter for the given project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `address` of an arbiter.
     */
    function getProjectArbiter(bytes32 _agreementHash) public view returns(address) {
        return projects[_agreementHash].arbiter;
    }

    /**
     * @dev Query for getting the feedback window for a client for the given project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `uint8` feedback window in days.
     */
    function getProjectFeedbackWindow(bytes32 _agreementHash) public view returns(uint8) {
        return projects[_agreementHash].feedbackWindow;
    }

    /**
     * @dev Query for getting the milestone start window for a client for the given project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `uint8` milestone start window in days.
     */
    function getProjectMilestoneStartWindow(bytes32 _agreementHash) public view returns(uint8) {
        return projects[_agreementHash].milestoneStartWindow;
    }

    /**
     * @dev Query for getting the start date for the given project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `uint` start date.
     */
    function getProjectStartDate(bytes32 _agreementHash) public view returns(uint) {
        return projects[_agreementHash].startDate;
    }

    /**
     * @dev Calculates sum and number of CSAT scores of ended & rated projects for the given maker`s address.
     * @param _maker An `address` of the maker to look up.
     * @return An `uint` sum of all scores and an `uint` number of projects counted in sum.
     */
    function makersAverageRating(address _maker) public view returns(uint, uint) {
        return calculateScore(_maker, ScoreType.CustomerSatisfaction);
    }

    /**
     * @dev Calculates sum and number of MSAT scores of ended & rated projects for the given client`s address.
     * @param _client An `address` of the client to look up.
     * @return An `uint` sum of all scores and an `uint` number of projects counted in sum.
     */
    function clientsAverageRating(address _client) public view returns(uint, uint) {
        return calculateScore(_client, ScoreType.MakerSatisfaction);
    }

    /**
     * @dev Returns hashes of all client`s projects
     * @param _client An `address` to look up.
     * @return `bytes32[]` of projects hashes.
     */
    function getClientProjects(address _client) public view returns(bytes32[]) {
        return clientProjects[_client];
    }

    /**
      @dev Returns hashes of all maker`s projects
     * @param _maker An `address` to look up.
     * @return `bytes32[]` of projects hashes.
     */
    function getMakerProjects(address _maker) public view returns(bytes32[]) {
        return makerProjects[_maker];
    }

    /**
     * @dev Checks if a project with the given hash exists.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return A `bool` stating for the project`s existence.
    */
    function checkIfProjectExists(bytes32 _agreementHash) public view returns(bool) {
        return projects[_agreementHash].client != address(0x0);
    }

    /**
     * @dev Query for getting end date of the given project.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `uint` end time of the project
     */
    function getProjectEndDate(bytes32 _agreementHash) public view returns(uint) {
        return projects[_agreementHash].endDate;
    }

    /**
     * @dev Returns preconfigured count of milestones for a project with the given hash.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `uint8` count of milestones set upon the project creation.
    */
    function getProjectMilestonesCount(bytes32 _agreementHash) public view returns(uint8) {
        return projects[_agreementHash].milestonesCount;
    }

    /**
     * @dev Returns configured for the given project arbiter fees.
     * @param _agreementHash A `bytes32` hash of the project`s agreement id.
     * @return An `uint` fixed fee and an `uint8` share fee of the project&#39;s arbiter.
     */
    function getProjectArbitrationFees(bytes32 _agreementHash) public view returns(uint, uint8) {
        return (
            projectArbiterFixedFee[_agreementHash],
            projectArbiterShareFee[_agreementHash]
        );
    }

    function getInfoForDisputeAndValidate(
        bytes32 _agreementHash,
        address _respondent,
        address _initiator,
        address _arbiter
    )
        public
        view
        returns(uint, uint8, address)
    {
        require(checkIfProjectExists(_agreementHash), "Project must exist.");
        Project memory project = projects[_agreementHash];
        address client = project.client;
        address maker = project.maker;
        require(project.arbiter == _arbiter, "Arbiter should be same as saved in project.");
        require(
            (_initiator == client && _respondent == maker) ||
            (_initiator == maker && _respondent == client),
            "Initiator and respondent must be different and equal to maker/client addresses."
        );
        (uint fixedFee, uint8 shareFee) = getProjectArbitrationFees(_agreementHash);
        return (fixedFee, shareFee, project.escrowContractAddress);
    }

    /**
     * @dev Pulls the current arbitration contract fixed & share fees and save them for a project.
     * @param _arbiter An `address` of arbitration contract.
     * @param _agreementHash A `bytes32` hash of agreement id.
     */
    function saveCurrentArbitrationFees(address _arbiter, bytes32 _agreementHash) internal {
        IDecoArbitration arbitration = IDecoArbitration(_arbiter);
        uint fixedFee;
        uint8 shareFee;
        (fixedFee, shareFee) = arbitration.getFixedAndShareFees();
        projectArbiterFixedFee[_agreementHash] = fixedFee;
        projectArbiterShareFee[_agreementHash] = shareFee;
    }

    /**
     * @dev Calculates the sum of scores and the number of ended and rated projects for the given client`s or
     *      maker`s address.
     * @param _address An `address` to look up.
     * @param _scoreType A `ScoreType` indicating what score should be calculated.
     *        `CustomerSatisfaction` type means that CSAT score for the given address as a maker should be calculated.
     *        `MakerSatisfaction` type means that MSAT score for the given address as a client should be calculated.
     * @return An `uint` sum of all scores and an `uint` number of projects counted in sum.
     */
    function calculateScore(
        address _address,
        ScoreType _scoreType
    )
        internal
        view
        returns(uint, uint)
    {
        bytes32[] memory allProjectsHashes = getProjectsByScoreType(_address, _scoreType);
        uint rating = 0;
        uint endedProjectsCount = 0;
        for (uint index = 0; index < allProjectsHashes.length; index++) {
            bytes32 agreementHash = allProjectsHashes[index];
            if (projects[agreementHash].endDate == 0) {
                continue;
            }
            uint8 score = getProjectScoreByType(agreementHash, _scoreType);
            if (score == 0) {
                continue;
            }
            endedProjectsCount++;
            rating = rating.add(score);
        }
        return (rating, endedProjectsCount);
    }

    /**
     * @dev Returns all projects for the given address depending on the provided score type.
     * @param _address An `address` to look up.
     * @param _scoreType A `ScoreType` to identify projects source.
     * @return `bytes32[]` of projects hashes either from `clientProjects` or `makerProjects` storage arrays.
     */
    function getProjectsByScoreType(address _address, ScoreType _scoreType) internal view returns(bytes32[]) {
        if (_scoreType == ScoreType.CustomerSatisfaction) {
            return makerProjects[_address];
        } else {
            return clientProjects[_address];
        }
    }

    /**
     * @dev Returns project score by the given type.
     * @param _agreementHash A `bytes32` hash of a project`s agreement id.
     * @param _scoreType A `ScoreType` to identify what score is requested.
     * @return An `uint8` score of the given project and of the given type.
     */
    function getProjectScoreByType(bytes32 _agreementHash, ScoreType _scoreType) internal view returns(uint8) {
        if (_scoreType == ScoreType.CustomerSatisfaction) {
            return projects[_agreementHash].customerSatisfaction;
        } else {
            return projects[_agreementHash].makerSatisfaction;
        }
    }

    /**
     * @dev Deploy DecoEscrow contract clone for the newly created project.
     * @param _newContractOwner An `address` of a new contract owner.
     * @return An `address` of a new deployed escrow contract.
     */
    function deployEscrowClone(address _newContractOwner) internal returns(address) {
        DecoRelay relay = DecoRelay(relayContractAddress);
        DecoEscrowFactory factory = DecoEscrowFactory(relay.escrowFactoryContractAddress());
        return factory.createEscrow(_newContractOwner, relay.milestonesContractAddress());
    }

    /**
     * @dev Check validness of maker&#39;s signature on project creation.
     * @param _maker An `address` of a maker.
     * @param _signature A `bytes` digital signature generated by a maker.
     * @param _agreementId A unique id of the agreement document for a project
     * @param _arbiter An `address` of a referee to settle all escalated disputes between parties.
     * @return A `bool` indicating validity of the signature.
     */
    function isMakersSignatureValid(address _maker, bytes _signature, string _agreementId, address _arbiter) internal view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(Proposal(_agreementId, _arbiter))
        ));
        address signatureAddress = digest.toEthSignedMessageHash().recover(_signature);
        return signatureAddress == _maker;
    }

    function hash(EIP712Domain eip712Domain) internal view returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(Proposal proposal) internal view returns (bytes32) {
        return keccak256(abi.encode(
            PROPOSAL_TYPEHASH,
            keccak256(bytes(proposal.agreementId)),
            proposal.arbiter
        ));
    }
}


/// @title Contract for Milesotone events and actions handling.
contract DecoMilestones is IDecoArbitrationTarget, DecoBaseProjectsMarketplace {

    address public constant ETH_TOKEN_ADDRESS = address(0x0);

    // struct to describe Milestone
    struct Milestone {
        uint8 milestoneNumber;

        // original duration of a milestone.
        uint32 duration;

        // track all adjustments caused by state changes Active <-> Delivered <-> Rejected
        // `adjustedDuration` time gets increased by the time that is spent by client
        // to provide a feedback when agreed milestone time is not exceeded yet.
        // Initial value is the same as duration.
        uint32 adjustedDuration;

        uint depositAmount;
        address tokenAddress;

        uint startedTime;
        uint deliveredTime;
        uint acceptedTime;

        // indicates that a milestone progress was paused.
        bool isOnHold;
    }

    // enumeration to describe possible milestone states.
    enum MilestoneState { Active, Delivered, Accepted, Rejected, Terminated, Paused }

    // map agreement id hash to milestones list.
    mapping (bytes32 => Milestone[]) public projectMilestones;

    // Logged when milestone state changes.
    event LogMilestoneStateUpdated (
        bytes32 indexed agreementHash,
        address indexed sender,
        uint timestamp,
        uint8 milestoneNumber,
        MilestoneState indexed state
    );

    event LogMilestoneDurationAdjusted (
        bytes32 indexed agreementHash,
        address indexed sender,
        uint32 amountAdded,
        uint8 milestoneNumber
    );

    /**
     * @dev Starts a new milestone for the project and deposit ETH in smart contract`s escrow.
     * @param _agreementHash A `bytes32` hash of the agreement id.
     * @param _depositAmount An `uint` of wei that are going to be deposited for a new milestone.
     * @param _duration An `uint` seconds of a milestone duration.
     */
    function startMilestone(
        bytes32 _agreementHash,
        uint _depositAmount,
        address _tokenAddress,
        uint32 _duration
    )
        external
    {
        uint8 completedMilestonesCount = uint8(projectMilestones[_agreementHash].length);
        if (completedMilestonesCount > 0) {
            Milestone memory lastMilestone = projectMilestones[_agreementHash][completedMilestonesCount - 1];
            require(lastMilestone.acceptedTime > 0, "All milestones must be accepted prior starting a new one.");
        }
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        require(
            projectsContract.getProjectClient(_agreementHash) == msg.sender,
            "Only project&#39;s client starts a miestone"
        );
        require(
            projectsContract.getProjectMilestonesCount(_agreementHash) > completedMilestonesCount,
            "Milestones count should not exceed the number configured in the project."
        );
        require(
            projectsContract.getProjectEndDate(_agreementHash) == 0,
            "Project should be active."
        );
        blockFundsInEscrow(
            projectsContract.getProjectEscrowAddress(_agreementHash),
            _depositAmount,
            _tokenAddress
        );
        uint nowTimestamp = now;
        projectMilestones[_agreementHash].push(
            Milestone(
                completedMilestonesCount + 1,
                _duration,
                _duration,
                _depositAmount,
                _tokenAddress,
                nowTimestamp,
                0,
                0,
                false
            )
        );
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            nowTimestamp,
            completedMilestonesCount + 1,
            MilestoneState.Active
        );
    }

    /**
     * @dev Maker delivers the current active milestone.
     * @param _agreementHash Project`s unique hash.
     */
    function deliverLastMilestone(bytes32 _agreementHash) external {
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        require(projectsContract.getProjectEndDate(_agreementHash) == 0, "Project should be active.");
        require(projectsContract.getProjectMaker(_agreementHash) == msg.sender, "Sender must be a maker.");
        uint nowTimestamp = now;
        uint8 milestonesCount = uint8(projectMilestones[_agreementHash].length);
        require(milestonesCount > 0, "There must be milestones to make a delivery.");
        Milestone storage milestone = projectMilestones[_agreementHash][milestonesCount - 1];
        require(
            milestone.startedTime > 0 && milestone.deliveredTime == 0 && milestone.acceptedTime == 0,
            "Milestone must be active, not delivered and not accepted."
        );
        require(!milestone.isOnHold, "Milestone must not be paused.");
        milestone.deliveredTime = nowTimestamp;
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            nowTimestamp,
            milestonesCount,
            MilestoneState.Delivered
        );
    }

    /**
     * @dev Project owner accepts the current delivered milestone.
     * @param _agreementHash Project`s unique hash.
     */
    function acceptLastMilestone(bytes32 _agreementHash) external {
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        require(projectsContract.getProjectEndDate(_agreementHash) == 0, "Project should be active.");
        require(projectsContract.getProjectClient(_agreementHash) == msg.sender, "Sender must be a client.");
        uint8 milestonesCount = uint8(projectMilestones[_agreementHash].length);
        require(milestonesCount > 0, "There must be milestones to accept a delivery.");
        Milestone storage milestone = projectMilestones[_agreementHash][milestonesCount - 1];
        require(
            milestone.startedTime > 0 &&
            milestone.acceptedTime == 0 &&
            milestone.deliveredTime > 0 &&
            milestone.isOnHold == false,
            "Milestone should be active and delivered, but not rejected, or already accepted, or put on hold."
        );
        uint nowTimestamp = now;
        milestone.acceptedTime = nowTimestamp;
        if (projectsContract.getProjectMilestonesCount(_agreementHash) == milestonesCount) {
            projectsContract.completeProject(_agreementHash);
        }
        distributeFundsInEscrow(
            projectsContract.getProjectEscrowAddress(_agreementHash),
            projectsContract.getProjectMaker(_agreementHash),
            milestone.depositAmount,
            milestone.tokenAddress
        );
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            nowTimestamp,
            milestonesCount,
            MilestoneState.Accepted
        );
    }

    /**
     * @dev Project owner rejects the current active milestone.
     * @param _agreementHash Project`s unique hash.
     */
    function rejectLastDeliverable(bytes32 _agreementHash) external {
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        require(projectsContract.getProjectEndDate(_agreementHash) == 0, "Project should be active.");
        require(projectsContract.getProjectClient(_agreementHash) == msg.sender, "Sender must be a client.");
        uint8 milestonesCount = uint8(projectMilestones[_agreementHash].length);
        require(milestonesCount > 0, "There must be milestones to reject a delivery.");
        Milestone storage milestone = projectMilestones[_agreementHash][milestonesCount - 1];
        require(
            milestone.startedTime > 0 &&
            milestone.acceptedTime == 0 &&
            milestone.deliveredTime > 0 &&
            milestone.isOnHold == false,
            "Milestone should be active and delivered, but not rejected, or already accepted, or on hold."
        );
        uint nowTimestamp = now;
        if (milestone.startedTime.add(milestone.adjustedDuration) > milestone.deliveredTime) {
            uint32 timeToAdd = uint32(nowTimestamp.sub(milestone.deliveredTime));
            milestone.adjustedDuration += timeToAdd;
            emit LogMilestoneDurationAdjusted (
                _agreementHash,
                msg.sender,
                timeToAdd,
                milestonesCount
            );
        }
        milestone.deliveredTime = 0;
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            nowTimestamp,
            milestonesCount,
            MilestoneState.Rejected
        );
    }

    /**
     * @dev Prepare arbitration target for a started dispute.
     * @param _idHash A `bytes32` hash of id.
     */
    function disputeStartedFreeze(bytes32 _idHash) public {
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        require(
            projectsContract.getProjectArbiter(_idHash) == msg.sender,
            "Freezing upon dispute start can be sent only by arbiter."
        );
        uint milestonesCount = projectMilestones[_idHash].length;
        require(milestonesCount > 0, "There must be active milestone.");
        Milestone storage lastMilestone = projectMilestones[_idHash][milestonesCount - 1];
        lastMilestone.isOnHold = true;
        emit LogMilestoneStateUpdated(
            _idHash,
            msg.sender,
            now,
            uint8(milestonesCount),
            MilestoneState.Paused
        );
    }

    /**
     * @dev React to an active dispute settlement with given parameters.
     * @param _idHash A `bytes32` hash of id.
     * @param _respondent An `address` of a respondent.
     * @param _respondentShare An `uint8` share for the respondent.
     * @param _initiator An `address` of a dispute initiator.
     * @param _initiatorShare An `uint8` share for the initiator.
     * @param _isInternal A `bool` indicating if dispute was settled by participants without an arbiter.
     * @param _arbiterWithdrawalAddress An `address` for sending out arbiter compensation.
     */
    function disputeSettledTerminate(
        bytes32 _idHash,
        address _respondent,
        uint8 _respondentShare,
        address _initiator,
        uint8 _initiatorShare,
        bool _isInternal,
        address _arbiterWithdrawalAddress
    )
        public
    {
        uint milestonesCount = projectMilestones[_idHash].length;
        require(milestonesCount > 0, "There must be at least one milestone.");
        Milestone memory lastMilestone = projectMilestones[_idHash][milestonesCount - 1];
        require(lastMilestone.isOnHold, "Last milestone must be on hold.");
        require(uint(_respondentShare).add(uint(_initiatorShare)) == 100, "Shares must be 100% in sum.");
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        (
            uint fixedFee,
            uint8 shareFee,
            address escrowAddress
        ) = projectsContract.getInfoForDisputeAndValidate (
            _idHash,
            _respondent,
            _initiator,
            msg.sender
        );
        distributeDisputeFunds(
            escrowAddress,
            lastMilestone.tokenAddress,
            _respondent,
            _initiator,
            _initiatorShare,
            _isInternal,
            _arbiterWithdrawalAddress,
            lastMilestone.depositAmount,
            fixedFee,
            shareFee
        );
        projectsContract.terminateProject(_idHash);
        emit LogMilestoneStateUpdated(
            _idHash,
            msg.sender,
            now,
            uint8(milestonesCount),
            MilestoneState.Terminated
        );
    }

    /**
     * @dev Check eligibility of a given address to perform operations,
     *      basically the address should be either client or maker.
     * @param _idHash A `bytes32` hash of id.
     * @param _addressToCheck An `address` to check.
     * @return A `bool` check status.
     */
    function checkEligibility(bytes32 _idHash, address _addressToCheck) public view returns(bool) {
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        return _addressToCheck == projectsContract.getProjectClient(_idHash) ||
            _addressToCheck == projectsContract.getProjectMaker(_idHash);
    }

    /**
     * @dev Check if target is ready for a dispute.
     * @param _idHash A `bytes32` hash of id.
     * @return A `bool` check status.
     */
    function canStartDispute(bytes32 _idHash) public view returns(bool) {
        uint milestonesCount = projectMilestones[_idHash].length;
        if (milestonesCount == 0)
            return false;
        Milestone memory lastMilestone = projectMilestones[_idHash][milestonesCount - 1];
        if (lastMilestone.isOnHold || lastMilestone.acceptedTime > 0)
            return false;
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        uint feedbackWindow = uint(projectsContract.getProjectFeedbackWindow(_idHash)).mul(24 hours);
        uint nowTimestamp = now;
        uint plannedDeliveryTime = lastMilestone.startedTime.add(uint(lastMilestone.adjustedDuration));
        if (plannedDeliveryTime < lastMilestone.deliveredTime || plannedDeliveryTime < nowTimestamp) {
            return false;
        }
        if (lastMilestone.deliveredTime > 0 &&
            lastMilestone.deliveredTime.add(feedbackWindow) < nowTimestamp)
            return false;
        return true;
    }

    /**
     * @dev Either project owner or maker can terminate the project in certain cases
     *      and the current active milestone must be marked as terminated for records-keeping.
     *      All blocked funds should be distributed in favor of eligible project party.
     *      The termination with this method initiated only by project contract.
     * @param _agreementHash Project`s unique hash.
     * @param _initiator An `address` of the termination initiator.
     */
    function terminateLastMilestone(bytes32 _agreementHash, address _initiator) public {
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        require(msg.sender == projectsContractAddress, "Method should be called by Project contract.");
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        address projectClient = projectsContract.getProjectClient(_agreementHash);
        address projectMaker = projectsContract.getProjectMaker(_agreementHash);
        require(
            _initiator == projectClient ||
            _initiator == projectMaker,
            "Initiator should be either maker or client address."
        );
        if (_initiator == projectClient) {
            require(canClientTerminate(_agreementHash));
        } else {
            require(canMakerTerminate(_agreementHash));
        }
        uint milestonesCount = projectMilestones[_agreementHash].length;
        if (milestonesCount == 0) return;
        Milestone memory lastMilestone = projectMilestones[_agreementHash][milestonesCount - 1];
        address projectEscrowContractAddress = projectsContract.getProjectEscrowAddress(_agreementHash);
        if (_initiator == projectClient) {
            unblockFundsInEscrow(
                projectEscrowContractAddress,
                lastMilestone.depositAmount,
                lastMilestone.tokenAddress
            );
        } else {
            distributeFundsInEscrow(
                projectEscrowContractAddress,
                _initiator,
                lastMilestone.depositAmount,
                lastMilestone.tokenAddress
            );
        }
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            now,
            uint8(milestonesCount),
            MilestoneState.Terminated
        );
    }

    /**
     * @dev Returns the last project milestone completion status and number.
     * @param _agreementHash Project&#39;s unique hash.
     * @return isAccepted A boolean flag for acceptance state, and milestoneNumber for the last milestone.
     */
    function isLastMilestoneAccepted(
        bytes32 _agreementHash
    )
        public
        view
        returns(bool isAccepted, uint8 milestoneNumber)
    {
        milestoneNumber = uint8(projectMilestones[_agreementHash].length);
        if (milestoneNumber > 0) {
            isAccepted = projectMilestones[_agreementHash][milestoneNumber - 1].acceptedTime > 0;
        } else {
            isAccepted = false;
        }
    }

    /**
     * @dev Client can terminate milestone if the last milestone delivery is overdue and
     *      milestone is not on hold. By default termination is not available.
     * @param _agreementHash Project`s unique hash.
     * @return `true` if the last project&#39;s milestone could be terminated by client.
     */
    function canClientTerminate(bytes32 _agreementHash) public view returns(bool) {
        uint milestonesCount = projectMilestones[_agreementHash].length;
        if (milestonesCount == 0) return false;
        Milestone memory lastMilestone = projectMilestones[_agreementHash][milestonesCount - 1];
        return lastMilestone.acceptedTime == 0 &&
            !lastMilestone.isOnHold &&
            lastMilestone.startedTime.add(uint(lastMilestone.adjustedDuration)) < now;
    }

    /**
     * @dev Maker can terminate milestone if delivery review is taking longer than project feedback window and
     *      milestone is not on hold, or if client doesn&#39;t start the next milestone for a period longer than
     *      project&#39;s milestone start window. By default termination is not available.
     * @param _agreementHash Project`s unique hash.
     * @return `true` if the last project&#39;s milestone could be terminated by maker.
     */
    function canMakerTerminate(bytes32 _agreementHash) public view returns(bool) {
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        uint feedbackWindow = uint(projectsContract.getProjectFeedbackWindow(_agreementHash)).mul(24 hours);
        uint milestoneStartWindow = uint(projectsContract.getProjectMilestoneStartWindow(
            _agreementHash
        )).mul(24 hours);
        uint projectStartDate = projectsContract.getProjectStartDate(_agreementHash);
        uint milestonesCount = projectMilestones[_agreementHash].length;
        if (milestonesCount == 0) return now.sub(projectStartDate) > milestoneStartWindow;
        Milestone memory lastMilestone = projectMilestones[_agreementHash][milestonesCount - 1];
        uint nowTimestamp = now;
        if (!lastMilestone.isOnHold &&
            lastMilestone.acceptedTime > 0 &&
            nowTimestamp.sub(lastMilestone.acceptedTime) > milestoneStartWindow)
            return true;
        return !lastMilestone.isOnHold &&
            lastMilestone.acceptedTime == 0 &&
            lastMilestone.deliveredTime > 0 &&
            nowTimestamp.sub(feedbackWindow) > lastMilestone.deliveredTime;
    }

    /*
     * @dev Block funds in escrow from balance to the blocked balance.
     * @param _projectEscrowContractAddress An `address` of project`s escrow.
     * @param _amount An `uint` amount to distribute.
     * @param _tokenAddress An `address` of a token.
     */
    function blockFundsInEscrow(
        address _projectEscrowContractAddress,
        uint _amount,
        address _tokenAddress
    )
        internal
    {
        if (_amount == 0) return;
        DecoEscrow escrow = DecoEscrow(_projectEscrowContractAddress);
        if (_tokenAddress == ETH_TOKEN_ADDRESS) {
            escrow.blockFunds(_amount);
        } else {
            escrow.blockTokenFunds(_tokenAddress, _amount);
        }
    }

    /*
     * @dev Unblock funds in escrow from blocked balance to the balance.
     * @param _projectEscrowContractAddress An `address` of project`s escrow.
     * @param _amount An `uint` amount to distribute.
     * @param _tokenAddress An `address` of a token.
     */
    function unblockFundsInEscrow(
        address _projectEscrowContractAddress,
        uint _amount,
        address _tokenAddress
    )
        internal
    {
        if (_amount == 0) return;
        DecoEscrow escrow = DecoEscrow(_projectEscrowContractAddress);
        if (_tokenAddress == ETH_TOKEN_ADDRESS) {
            escrow.unblockFunds(_amount);
        } else {
            escrow.unblockTokenFunds(_tokenAddress, _amount);
        }
    }

    /**
     * @dev Distribute funds in escrow from blocked balance to the target address.
     * @param _projectEscrowContractAddress An `address` of project`s escrow.
     * @param _distributionTargetAddress Target `address`.
     * @param _amount An `uint` amount to distribute.
     * @param _tokenAddress An `address` of a token.
     */
    function distributeFundsInEscrow(
        address _projectEscrowContractAddress,
        address _distributionTargetAddress,
        uint _amount,
        address _tokenAddress
    )
        internal
    {
        if (_amount == 0) return;
        DecoEscrow escrow = DecoEscrow(_projectEscrowContractAddress);
        if (_tokenAddress == ETH_TOKEN_ADDRESS) {
            escrow.distributeFunds(_distributionTargetAddress, _amount);
        } else {
            escrow.distributeTokenFunds(_distributionTargetAddress, _tokenAddress, _amount);
        }
    }

    /**
     * @dev Distribute project funds between arbiter and project parties.
     * @param _projectEscrowContractAddress An `address` of project`s escrow.
     * @param _tokenAddress An `address` of a token.
     * @param _respondent An `address` of a respondent.
     * @param _initiator An `address` of an initiator.
     * @param _initiatorShare An `uint8` iniator`s share.
     * @param _isInternal A `bool` indicating if dispute was settled solely by project parties.
     * @param _arbiterWithdrawalAddress A withdrawal `address` of an arbiter.
     * @param _amount An `uint` amount for distributing between project parties and arbiter.
     * @param _fixedFee An `uint` fixed fee of an arbiter.
     * @param _shareFee An `uint8` share fee of an arbiter.
     */
    function distributeDisputeFunds(
        address _projectEscrowContractAddress,
        address _tokenAddress,
        address _respondent,
        address _initiator,
        uint8 _initiatorShare,
        bool _isInternal,
        address _arbiterWithdrawalAddress,
        uint _amount,
        uint _fixedFee,
        uint8 _shareFee
    )
        internal
    {
        if (!_isInternal && _arbiterWithdrawalAddress != address(0x0)) {
            uint arbiterFee = getArbiterFeeAmount(_fixedFee, _shareFee, _amount, _tokenAddress);
            distributeFundsInEscrow(
                _projectEscrowContractAddress,
                _arbiterWithdrawalAddress,
                arbiterFee,
                _tokenAddress
            );
            _amount = _amount.sub(arbiterFee);
        }
        uint initiatorAmount = _amount.mul(_initiatorShare).div(100);
        distributeFundsInEscrow(
            _projectEscrowContractAddress,
            _initiator,
            initiatorAmount,
            _tokenAddress
        );
        distributeFundsInEscrow(
            _projectEscrowContractAddress,
            _respondent,
            _amount.sub(initiatorAmount),
            _tokenAddress
        );
    }

    /**
     * @dev Calculates arbiter`s fee.
     * @param _fixedFee An `uint` fixed fee of an arbiter.
     * @param _shareFee An `uint8` share fee of an arbiter.
     * @param _amount An `uint` amount for distributing between project parties and arbiter.
     * @param _tokenAddress An `address` of a token.
     * @return An `uint` amount allotted to the arbiter.
     */
    function getArbiterFeeAmount(uint _fixedFee, uint8 _shareFee, uint _amount, address _tokenAddress)
        internal
        pure
        returns(uint)
    {
        if (_tokenAddress != ETH_TOKEN_ADDRESS) {
            _fixedFee = 0;
        }
        return _amount.sub(_fixedFee).mul(uint(_shareFee)).div(100).add(_fixedFee);
    }
}