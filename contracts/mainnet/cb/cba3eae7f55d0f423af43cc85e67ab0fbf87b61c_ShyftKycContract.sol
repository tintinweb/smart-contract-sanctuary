/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.7.1;
//SPDX-License-Identifier: UNLICENSED

/* New ERC23 contract interface */

interface IErc223 {
    function totalSupply() external view returns (uint);

    function balanceOf(address who) external view returns (uint);

    function transfer(address to, uint value) external returns (bool ok);
    function transfer(address to, uint value, bytes memory data) external returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/**
* @title Contract that will work with ERC223 tokens.
*/

interface IErc223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes memory _data) external returns (bool ok);
}


interface IErc20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



interface IShyftCacheGraph {
    function compileCacheGraph(address _identifiedAddress, uint16 _idx) external;

    function getKycCanSend( address _senderIdentifiedAddress,
                            address _receiverIdentifiedAddress,
                            uint256 _amount,
                            uint256 _bip32X_type,
                            bool _requiredConsentFromAllParties,
                            bool _payForDirty) external returns (uint8 result);

    function getActiveConsentedTrustChannelBitFieldForPair( address _senderIdentifiedAddress,
                                                            address _receiverIdentifiedAddress) external returns (uint32 result);

    function getActiveTrustChannelBitFieldForPair(  address _senderIdentifiedAddress,
                                                    address _receiverIdentifiedAddress) external returns (uint32 result);

    function getActiveConsentedTrustChannelRoutePossible(   address _firstAddress,
                                                            address _secondAddress,
                                                            address _trustChannelAddress) external view returns (bool result);

    function getActiveTrustChannelRoutePossible(address _firstAddress,
                                                address _secondAddress,
                                                address _trustChannelAddress) external view returns (bool result);

    function getRelativeTrustLevelOnlyClean(address _senderIdentifiedAddress,
                                            address _receiverIdentifiedAddress,
                                            uint256 _amount,
                                            uint256 _bip32X_type,
                                            bool _requiredConsentFromAllParties,
                                            bool _requiredActive) external returns (int16 relativeTrustLevel, int16 externalTrustLevel);

    function calculateRelativeTrustLevel(   uint32 _trustChannelIndex,
                                            uint256 _foundChannelRulesBitField,
                                            address _senderIdentifiedAddress,
                                            address _receiverIdentifiedAddress,
                                            uint256 _amount,
                                            uint256 _bip32X_type,
                                            bool _requiredConsentFromAllParties,
                                            bool _requiredActive) external returns(int16 relativeTrustLevel, int16 externalTrustLevel);
}



interface IShyftKycContractRegistry  {
    function isShyftKycContract(address _addr) external view returns (bool result);
    function getCurrentContractAddress() external view returns (address);
    function getContractAddressOfVersion(uint _version) external view returns (address);
    function getContractVersionOfAddress(address _address) external view returns (uint256 result);

    function getAllTokenLocations(address _addr, uint256 _bip32X_type) external view returns (bool[] memory resultLocations, uint256 resultNumFound);
    function getAllTokenLocationsAndBalances(address _addr, uint256 _bip32X_type) external view returns (bool[] memory resultLocations, uint256[] memory resultBalances, uint256 resultNumFound, uint256 resultTotalBalance);
}



/// @dev Inheritable constants for token types

contract TokenConstants {

    //@note: reference from https://github.com/satoshilabs/slips/blob/master/slip-0044.md
    // hd chaincodes are 31 bits (max integer value = 2147483647)

    //@note: reference from https://chainid.network/
    // ethereum-compatible chaincodes are 32 bits

    // given these, the final "nativeType" needs to be a mix of both.

    uint256 constant TestNetTokenOffset = 2**128;
    uint256 constant PrivateNetTokenOffset = 2**192;

    uint256 constant ShyftTokenType = 7341;
    uint256 constant EtherTokenType = 60;
    uint256 constant EtherClassicTokenType = 61;
    uint256 constant RootstockTokenType = 137;

    //Shyft Testnets
    uint256 constant BridgeTownTokenType = TestNetTokenOffset + 0;

    //Ethereum Testnets
    uint256 constant GoerliTokenType = TestNetTokenOffset + 1;
    uint256 constant KovanTokenType = TestNetTokenOffset + 2;
    uint256 constant RinkebyTokenType = TestNetTokenOffset + 3;
    uint256 constant RopstenTokenType = TestNetTokenOffset + 4;

    //Ethereum Classic Testnets
    uint256 constant KottiTokenType = TestNetTokenOffset + 5;

    //Rootstock Testnets
    uint256 constant RootstockTestnetTokenType = TestNetTokenOffset + 6;

    //@note:@here:@deploy: need to hardcode test and/or privatenet for deploy on various blockchains
    bool constant IsTestnet = false;
    bool constant IsPrivatenet = false;

    //@note:@here:@deploy: need to hardcode NativeTokenType for deploy on various blockchains
//    uint256 constant NativeTokenType = ShyftTokenType;
}
// pragma experimental ABIEncoderV2;








/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}








interface IShyftKycContract is IErc20, IErc223, IErc223ReceivingContract {
    function balanceOf(address tokenOwner) external view override(IErc20, IErc223) returns (uint balance);
    function totalSupply() external view override(IErc20, IErc223) returns (uint);
    function transfer(address to, uint tokens) external override(IErc20, IErc223) returns (bool success);

    function getNativeTokenType() external view returns (uint256 result);

    function withdrawNative(address payable _to, uint256 _value) external returns (bool ok);
    function withdrawToExternalContract(address _to, uint256 _value) external returns (bool ok);
    function withdrawToShyftKycContract(address _shyftKycContractAddress, address _to, uint256 _value) external returns (bool ok);

    function migrateFromKycContract(address _to) external payable returns(bool result);
    function updateContract(address _addr) external returns (bool);

    function getBalanceBip32X(address _identifiedAddress, uint256 _bip32X_type) external view returns (uint256 balance);

    function getOnlyAcceptsKycInput(address _identifiedAddress) external view returns (bool result);
    function getOnlyAcceptsKycInputPermanently(address _identifiedAddress) external view returns (bool result);
}



/// @dev | Shyft Core :: Shyft Kyc Contract
///      |
///      | This contract is the nucleus of all of the Shyft stack. This current v1 version has basic functionality for upgrading and connects to the Shyft Cache Graph via Routing for further system expansion.
///      |
///      | It should be noted that all payable functions should utilize revert, as they are dealing with assets.
///      |
///      | "Bip32X" & Synthetics - Here we're using an extension of the Bip32 standard that effectively uses a hash of contract address & "chainId" to allow any erc20/erc223 contract to allow assets to move through Shyft's opt-in compliance rails.
///      | Ex. Ethereum = 60
///      | Shyft Network = 7341
///      |
///      | This contract is built so that when the totalSupply is asked for, much like transfer et al., it only references the ShyftTokenType. For getting the native balance of any specific Bip32X token, you'd call "getTotalSupplyBip32X" with the proper contract address.
///      |
///      | "Auto Migration"
///      | This contract was built with the philosophy that while there needs to be *some* upgrade path, unilaterally changing the existing contract address for Users is a bad idea in practice. Instead, we use a versioning system with the ability for users to set flags to automatically upgrade their liquidity on send into this particular contract, to any other contracts that have been updated so far (in a recursive manner).
///      |
///      | Auto-Migration of assets flow:
///      | 1. registry contract is set up
///      | 2. upgrade is called by registry contract
///      | 3. calls to fallback looks to see if upgrade is set
///      | 4. if so it asks the registry for the current contract address
///      | 5. it then uses the "migrateFromKycContract", which on the receiver's end will update the _to address passed in with the progression and now has the value from the "migrateFromKycContract"'s payable and thus the native fuel, to back the token increase to the _to's account.
///      |
///      |
///      | What's Next (V2 notes):
///      |
///      | "Shyft Safe" - timelocked assets that will work with Byfrost
///      | "Shyft Byfrost" - economic finality bridge infrastructure
///      |
///      | Compliance Channels:
///      | Addresses that only accept kyc input should be able to receive packages by the bridge that are only kyc'd across byfrost.
///      | Ultimate accountability chain could be difficult, though a hash map of critical ipfs resources of chain data could suffice.
///      | This would be the same issue as data accountability by trying to leverage multiple chains for data sales as well.

contract ShyftKycContract is IShyftKycContract, TokenConstants {
    /// @dev Event for migration to another shyft kyc contract (of higher or equal version).
    event EVT_migrateToKycContract(address indexed updatedShyftKycContractAddress, uint256 updatedContractBalance, address indexed kycContractAddress, address indexed to, uint256 _amount);
    /// @dev Event for migration to another shyft kyc contract (from lower or equal version).
    event EVT_migrateFromContract(address indexed sendingKycContract, uint256 totalSupplyBip32X, uint256 msgValue, uint256 thisBalance);

    /// @dev Event for receipt of native assets.
    event EVT_receivedNativeBalance(address indexed _from, uint256 _value);

    /// @dev Event for withdraw to address.
    event EVT_WithdrawToAddress(address _from, address _to, uint256 _value);
    /// @dev Event for withdraw to a specific shyft smart contract.
    event EVT_WithdrawToShyftKycContract(address _from, address _to, uint256 _value);
    /// @dev Event for withdraw to external contract (w/ Erc223 fallbacks).
    event EVT_WithdrawToExternalContract(address _from, address _to, uint256 _value);

    /// @dev Event for getting an erc223 asset inbound to this contract.
    event EVT_Bip32X_TypeTokenFallback(address msgSender, address _from, uint256 value, uint256 nativeTokenType, uint256 bip32X_type);

    event EVT_TransferAndMintBip32X_type(address contractAddress, address msgSender, uint256 value, uint256 bip32X_type);
    event EVT_TransferAndBurnBip32X_type(address contractAddress, address msgSender, address to, uint256 value, uint256 bip32X_type);

    event EVT_TransferBip32X_type(address msgSender, address to, uint256 value, uint256 bip32X_type);

    /* ERC223 events */
    event EVT_Erc223TokenFallback(address _from, uint256 _value, bytes _data);

    using SafeMath for uint256;

    /// @dev Mapping of total supply specific bip32x assets.
    mapping(uint256 => uint256) totalSupplyBip32X;
    /// @dev Mapping of users to their balances of specific bip32x assets.
    mapping(address => mapping(uint256 => uint256)) balances;
    /// @dev Mapping of users to users with amount of allowance set for specific bip32x assets.
    mapping(address => mapping(address => mapping(uint256 => uint256))) allowed;

    /// @dev Mapping of users to whether they have set auto-upgrade enabled.
    mapping(address => bool) autoUpgradeEnabled;
    /// @dev Mapping of users to whether they Accepts Kyc Input only.
    mapping(address => bool) onlyAcceptsKycInput;
    /// @dev Mapping of users to whether their Accepts Kyc Input option is locked permanently.
    mapping(address => bool) lockOnlyAcceptsKycInputPermanently;

    /// @dev mutex lock, prevent recursion in functions that use external function calls
    bool locked;

    /// @dev Whether there has been an upgrade from this contract.
    bool public hasBeenUpdated;
    /// @dev The address of the next upgraded Shyft Kyc Contract.
    address public updatedShyftKycContractAddress;
    /// @dev The address of the Shyft Kyc Registry contract.
    address public shyftKycContractRegistryAddress;

    /// @dev The address of the Shyft Cache Graph contract.
    address public shyftCacheGraphAddress = address(0);

    /// @dev The signature for triggering 'tokenFallback' in erc223 receiver contracts.
    bytes4 constant shyftKycContractSig = bytes4(keccak256("fromShyftKycContract(address,address,uint256,uint256)")); // function signature

    /// @dev The signature for the upgrade event.
    bytes4 shyftKycContractTokenUpgradeSig = bytes4(keccak256("updateShyftToken(address,uint256,uint256)")); // function signature

    /// @dev The origin of the Byfrost link, if this contract is used as such. follows chainId.
    bool public byfrostOrigin;
    /// @dev Flag for whether the Byfrost state has been set.
    bool public setByfrostOrigin;

    /// @dev The owner of this contract.
    address public owner;
    /// @dev The native Bip32X type of this network. Ethereum is 60, Shyft is 7341, etc.
    uint256 nativeBip32X_type;

    /// @param _nativeBip32X_type The native Bip32X type of this network. Ethereum is 60, Shyft is 7341, etc.
    /// @dev Invoke the constructor for ShyftSafe, which sets the owner and nativeBip32X_type class variables
    constructor(uint256 _nativeBip32X_type) {
        owner = msg.sender;

        nativeBip32X_type = _nativeBip32X_type;
    }

    /// @dev Gets the native bip32x token (should correspond to "chainid")
    /// @return result the native bip32x token (should correspond to "chainid")

    function getNativeTokenType() public override view returns (uint256 result) {
        return nativeBip32X_type;
    }

    /// @param _tokenAmount The amount of tokens to be allocated.
    /// @param _bip32X_type The Bip32X type that represents the synthetic tokens that will be allocated.
    /// @param _distributionContract The public address of the distribution contract, that the tokens are allocated for.
    /// @dev Set by the owner, this functions sets it such that this contract was deployed on a Byfrost arm of the Shyft Network (on Ethereum for example). With this is a token grant that this contract should make to a specific distribution contract (ie. in the case of the initial Shyft Network launch, we have a small allocation originating on the Ethereum network).
    /// @notice | for created kyc contracts on other chains, they can be instantiated with specific bip32X_type amounts
    ///         | (for example, the shyft distribution contract on eth vs. shyft native)
    ///         |  '  uint256 bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, _erc20ContractAddress)));
    ///         |  '  bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, msg.sender)));
    ///         | the bip32X_type is formed by the hash of the native bip32x type (which is unique per-platform, as it depends on
    ///         | the deployed contract address) - byfrost only touches non-replay networks.
    ///         | so the formula for the bip32X_type would be HASH [ byfrost main chain bip32X_type ] & [ byfrost main chain kyc contract address ]
    ///         | these minted tokens are given to the distribution contract for further distribution. This is all this contract
    ///         | needs to know about the distribution contract.
    /// @return result
    ///    | 2 = set byfrost as origin
    ///    | 1 = already set byfrost origin
    ///    | 0 = not owner

    function setByfrostNetwork(uint256 _tokenAmount, uint256 _bip32X_type, address _distributionContract) public returns (uint8 result) {
        if (msg.sender == owner) {
            if (setByfrostOrigin == false) {
                byfrostOrigin = true;
                setByfrostOrigin = true;

                balances[_distributionContract][_bip32X_type] = _tokenAmount;

                //set byfrost as origin
                return 2;
            } else {
                //already set
                return 1;
            }
        } else {
            //not owner
            return 0;
        }
    }

    /// @dev Set by the owner, this function sets it such that this contract was deployed on the primary Shyft Network. No further calls to setByfrostNetwork may be made.
    /// @return result
    ///    | 2 = set primary network
    ///    | 1 = already set byfrost origin
    ///    | 0 = not owner

    function setPrimaryNetwork() public returns (uint8 result) {
        if (msg.sender == owner) {
            if (setByfrostOrigin == false) {
                setByfrostOrigin = true;

                //set primary network
                return 2;
            } else {
                //already set byfrost origin
                return 1;
            }
        } else {
            //not owner
            return 0;
        }
    }

    /// @dev Removes the owner (creator of this contract)'s control completely. Functions such as linking the registry & cachegraph (& shyftSafe's setBridge), and importantly initializing this as a byfrost contract, are triggered by the owner, and as such a setting phase and afterwards triggering this function could be seen as a completely appropriate workflow.
    /// @return true if the owner is removed successfully
    function removeOwner() public returns (bool) {
        require(msg.sender == owner);

        owner = address(0);
        return true;
    }

    /// @param _shyftCacheGraphAddress The smart contract address for the Shyft CacheGraph that should be linked.
    /// @dev Links Shyft CacheGraph to this contract's function flow.
    /// @return result
    ///    | 0: not owner
    ///    | 1: set shyft cache graph address

    function setShyftCacheGraphAddress(address _shyftCacheGraphAddress) public returns (uint8 result) {
        require(_shyftCacheGraphAddress != address(0));
        if (owner == msg.sender) {
            shyftCacheGraphAddress = _shyftCacheGraphAddress;

            //cacheGraph contract address set
            return 1;
        } else {
            //not owner
            return 0;
        }
    }

    //---------------- Cache Graph Utilization ----------------//

    /// @param _identifiedAddress The public address for the recipient to send assets (tokens) to.
    /// @param _amount The amount of assets that will be sent.
    /// @param _bip32X_type The bip32X type of the assets that will be sent. These are synthetic (wrapped) assets, based on atomic locking.
    /// @param _requiredConsentFromAllParties Whether to match the routing algorithm on the "consented" layer which indicates 2 way buy in of counterparty's attestation(s)
    /// @param _payForDirty Whether the sender will pay the additional cost to unify a cachegraph's relationships (if not, it will not complete).
    /// @dev | Performs a "kyc send", which is an automatic search between addresses for counterparty relationships within Trust Channels (whos rules dictate accessibility for auditing/enforcement/jurisdiction/etc.). If there is a match, the designated amount of assets is sent to the recipient.
    ///      | As there are accessor methods to check whether or not the counterparty's cachegraph is "dirty", there is little need to pass a "true" unless the transaction is critical (eg. DeFi atomic flash wrap) and there is a chance that there will need to be a unification pass before the transaction can pass with full assurety.
    /// @notice | If the recipient has flags set to indicate that they *only* want to receive assets from kyc sources, *all* of the regular transfer functions will block except this one, and this one only passes on success.
    /// @return result
    ///    | 0 = not enough balance to send
    ///    | 1 = consent required
    ///    | 2 = transfer cannot be processed due to transfer rules
    ///    | 3 = successful transfer

    function kycSend(address _identifiedAddress, uint256 _amount, uint256 _bip32X_type, bool _requiredConsentFromAllParties, bool _payForDirty) public returns (uint8 result) {
        if (balances[msg.sender][_bip32X_type] >= _amount) {
            if (onlyAcceptsKycInput[_identifiedAddress] == false || (onlyAcceptsKycInput[_identifiedAddress] == true && _requiredConsentFromAllParties == true)) {
                IShyftCacheGraph shyftCacheGraph = IShyftCacheGraph(shyftCacheGraphAddress);

                uint8 kycCanSendResult = shyftCacheGraph.getKycCanSend(msg.sender, _identifiedAddress, _amount, _bip32X_type, _requiredConsentFromAllParties, _payForDirty);

                //getKycCanSend return 3 = can transfer successfully
                if (kycCanSendResult == 3) {
                    balances[msg.sender][_bip32X_type] = balances[msg.sender][_bip32X_type].sub(_amount);
                    balances[_identifiedAddress][_bip32X_type] = balances[_identifiedAddress][_bip32X_type].add(_amount);

                    //successful transfer
                    return 3;
                } else {
                    //transfer cannot be processed due to transfer rules
                    return 2;
                }
            } else {
                //consent required
                return 1;
            }
        } else {
            //not enough balance to send
            return 0;
        }
    }

    //---------------- Shyft KYC balances, fallback, send, receive, and withdrawal ----------------//


    /// @dev mutex locks transactions ordering so that multiple chained calls cannot complete out of order.

    modifier mutex() {
        if (locked) revert();
        locked = true;
        _;
        locked = false;
    }

    /// @param _addr The Shyft Kyc Contract Registry address to set to.
    /// @dev Upgrades the contract. Can only be called by a pre-set Shyft Kyc Contract Registry contract. Can only be called once.
    /// @return returns true if the function passes, otherwise reverts if the message sender is not the shyft kyc registry contract.

    function updateContract(address _addr) public override returns (bool) {
        require(msg.sender == shyftKycContractRegistryAddress);
        require(hasBeenUpdated == false);

        hasBeenUpdated = true;
        updatedShyftKycContractAddress = _addr;
        return true;
    }

    /// @param _addr The Shyft Kyc Contract Registry address to set to.
    /// @dev Sets the Shyft Kyc Contract Registry address, so this contract can be upgraded.
    /// @return returns true if the function passes, otherwise reverts if the message sender is not the owner (deployer) of this contract.

    function setShyftKycContractRegistryAddress(address _addr) public returns (bool) {
        require(msg.sender == owner);

        shyftKycContractRegistryAddress = _addr;
        return true;
    }

    /// @param _to The destination address to withdraw to.
    /// @dev Withdraws all assets of this User to a specific address (only native assets, ie. Ether on Ethereum, Shyft on Shyft Network).
    /// @return balance the number of tokens of that specific bip32x type in the user's account

    function withdrawAllNative(address payable _to) public returns (uint) {
        uint _bal = balances[msg.sender][ShyftTokenType];
        withdrawNative(_to, _bal);
        return _bal;
    }

    /// @param _identifiedAddress The address of the User.
    /// @param _bip32X_type The Bip32X type to check.
    /// @dev Gets balance for Shyft KYC token type & synthetics for a specfic user.
    /// @return balance the number of tokens of that specific bip32x type in the user's account

    function getBalanceBip32X(address _identifiedAddress, uint256 _bip32X_type) public view override returns (uint256 balance) {
        return balances[_identifiedAddress][_bip32X_type];
    }

    /// @param _bip32X_type The Bip32X type to check.
    /// @dev Gets the total supply for a specific bip32x token.
    /// @return balance the number of tokens of that specific bip32x type in this contract

    function getTotalSupplyBip32X(uint256 _bip32X_type) public view returns (uint256 balance) {
        return totalSupplyBip32X[_bip32X_type];
    }

    /// @dev This fallback function applies value to nativeBip32X_type Token (Ether on Ethereum, Shyft on Shyft Network, etc). It also uses auto-upgrade logic so that users can automatically have their coins in the latest wallet (if everything is opted in across all contracts by the user).

    receive() external payable {
        //@note: this is the auto-upgrade path, which is an opt-in service to the users to be able to send any or all tokens
        // to an upgraded kycContract.
        if (hasBeenUpdated && autoUpgradeEnabled[msg.sender]) {
            //@note: to prevent tokens from ever getting "stuck", this contract can only send to itself in a very
            // specific manner.
            //
            // for example, the "withdrawNative" function will output native fuel to a destination.
            // If it was sent to this contract, this function will trigger and know that the msg.sender is
            // the originating kycContract.

            if (msg.sender != address(this)) {
                // stop the process if the message sender has set a flag that only allows kyc input
                require(onlyAcceptsKycInput[msg.sender] == false);

                // burn tokens in this contract
                uint256 existingSenderBalance = balances[msg.sender][nativeBip32X_type];

                balances[msg.sender][nativeBip32X_type] = 0;
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(existingSenderBalance);

                //~70k gas for the contract "call"
                //and 90k gas for the value transfer within this.
                // total = ~160k+checks gas to perform this transaction.
                bool didTransferSender = migrateToKycContract(updatedShyftKycContractAddress, msg.sender, existingSenderBalance.add(msg.value));

                if (didTransferSender == true) {

                } else {
                    //@note: reverts since a transactional event has occurred.
                    revert();
                }
            } else {
                //****************************************************************************************************//
                //@note: This *must* be the only route where tx.origin has to matter.
                //****************************************************************************************************//

                // duplicating the logic here for higher deploy cost vs. lower transactional costs (consider user costs
                // where all users would want to migrate)

                // burn tokens in this contract
                uint256 existingOriginBalance = balances[tx.origin][nativeBip32X_type];

                balances[tx.origin][nativeBip32X_type] = 0;
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(existingOriginBalance);

                //~70k gas for the contract "call"
                //and 90k gas for the value transfer within this.
                // total = ~160k+checks gas to perform this transaction.

                bool didTransferOrigin = migrateToKycContract(updatedShyftKycContractAddress, tx.origin, existingOriginBalance.add(msg.value));

                if (didTransferOrigin == true) {

                } else {
                    //@note: reverts since a transactional event has occurred.
                    revert();
                }
            }
        } else {
            //@note: never accept this contract sending raw value to this fallback function, unless explicit cases
            // have been met.
            //@note: public addresses do not count as kyc'd addresses
            if (msg.sender != address(this) && onlyAcceptsKycInput[msg.sender] == true) {
                revert();
            }

            balances[msg.sender][nativeBip32X_type] = balances[msg.sender][nativeBip32X_type].add(msg.value);
            totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].add(msg.value);

            emit EVT_receivedNativeBalance(msg.sender, msg.value);
        }
    }

    /// @param _kycContractAddress The Shyft Kyc Contract to migrate to.
    /// @param _to The user's address to migrate to
    /// @param _amount The amount of tokens to migrate.
    /// @dev Internal function to migrates the user's assets to another Shyft Kyc Contract. This function is called from the fallback to allocate tokens properly to the upgraded contract.
    /// @return result
    ///    | true = transfer complete
    ///    | false = transfer did not complete

    function migrateToKycContract(address _kycContractAddress, address _to, uint256 _amount) internal returns (bool result) {
        // call upgraded contract so that tokens are forwarded to the new contract under _to's account.
        IShyftKycContract updatedKycContract = IShyftKycContract(updatedShyftKycContractAddress);

        emit EVT_migrateToKycContract(updatedShyftKycContractAddress, address(updatedShyftKycContractAddress).balance, _kycContractAddress, _to, _amount);

        // sending to ShyftKycContracts only; migrateFromKycContract uses ~75830 - 21000 gas to execute,
        // with a registry lookup, so adding in a bit more for future contracts.
        bool transferResult = updatedKycContract.migrateFromKycContract{value: _amount, gas: 100000}(_to);

        if (transferResult == true) {
            //transfer complete
            return true;
        } else {
            //transfer did not complete
            return false;
        }
    }

    /// @param _to The user's address to migrate to.
    /// @dev | Migrates the user's assets from another Shyft Kyc Contract. The following conditions have to pass:
    ///      | a) message sender is a shyft kyc contract,
    ///      | b) sending shyft kyc contract is not of a later version than this one
    ///      | c) user on this shyft kyc contract have no restrictions on only accepting KYC input (will ease in v2)
    /// @return result
    ///    | true = migration completed successfully
    ///    | [revert] = reverts on any situation that fails on the above parameters

    function migrateFromKycContract(address _to) public payable override returns (bool result) {
        //@note: doing a very strict check to make sure no unwanted additional tokens can be created.
        // the way this work is that this.balance is updated *before* this code runs.
        // thus, as long as we've always updated totalSupplyBip32X when we've created or destroyed tokens, we'll
        // always be able to check against this.balance.

        //regarding an issue found:
        //"Smart contracts, though they may not expect it, can receive ether forcibly, or could be deployed at an
        // address that already received some ether."
        // from:
        // "require(totalSupplyBip32X[nativeBip32X_type].add(msg.value) == address(this).balance);"
        //
        // the worst case scenario in some non-atomic calls (without going through withdrawToShyftKycContract for example)
        // is that someone self-destructs a contract and forcibly sends ether to this address, before this is triggered by
        // someone using it.

        // solution:
        // we cannot do a simple equality check for address(this).balance. instead, we use an less-than-or-equal-to, as
        // when the worst case above occurs, the total supply of this synthetic will be less than the balance within this
        // contract.

        require(totalSupplyBip32X[nativeBip32X_type].add(msg.value) <= address(this).balance);

        bool doContinue = true;

        IShyftKycContractRegistry contractRegistry = IShyftKycContractRegistry(shyftKycContractRegistryAddress);

        // check if only using a known kyc contract communication cycle, then verify the message sender is a kyc contract.
        if (contractRegistry.isShyftKycContract(address(msg.sender)) == false) {
            doContinue = false;
        } else {
            // only allow migration from equal or older versions of Shyft Kyc Contracts, via registry lookup.
            if (contractRegistry.getContractVersionOfAddress(address(msg.sender)) > contractRegistry.getContractVersionOfAddress(address(this))) {
                doContinue = false;
            }
        }

        // block transfers if the recipient only allows kyc input
        if (onlyAcceptsKycInput[_to] == true) {
            doContinue = false;
        }

        if (doContinue == true) {
            emit EVT_migrateFromContract(msg.sender, totalSupplyBip32X[nativeBip32X_type], msg.value, address(this).balance);

            balances[_to][nativeBip32X_type] = balances[_to][nativeBip32X_type].add(msg.value);
            totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].add(msg.value);

            //transfer complete
            return true;
        } else {
            //kyc contract not in registry
            //@note: transactional event has occurred, so revert() is necessary
            revert();
            //return false;
        }
    }

    /// @param _onlyAcceptsKycInputValue Whether to accept only Kyc Input.
    /// @dev Sets whether to accept only Kyc Input in the future.
    /// @return result
    ///    | true = updated onlyAcceptsKycInput
    ///    | false = cannot modify onlyAcceptsKycInput, as it is locked permanently by user

    function setOnlyAcceptsKycInput(bool _onlyAcceptsKycInputValue) public returns (bool result) {
        if (lockOnlyAcceptsKycInputPermanently[msg.sender] == false) {
            onlyAcceptsKycInput[msg.sender] = _onlyAcceptsKycInputValue;

            //updated onlyAcceptsKycInput
            return true;
        } else {

            //cannot modify onlyAcceptsKycInput, as it is locked permanently by user
            return false;
        }
    }

    /// @dev Gets whether the user has set Accepts Kyc Input.
    /// @return result
    ///    | true = set lock for onlyAcceptsKycInput
    ///    | false = already set lock for onlyAcceptsKycInput

    function setLockOnlyAcceptsKycInputPermanently() public returns (bool result) {
        if (lockOnlyAcceptsKycInputPermanently[msg.sender] == false) {
            lockOnlyAcceptsKycInputPermanently[msg.sender] = true;
            //set lock for onlyAcceptsKycInput
            return true;
        } else {
            //already set lock for onlyAcceptsKycInput
            return false;
        }
    }

    /// @param _identifiedAddress The public address to check.
    /// @dev Gets whether the user has set Accepts Kyc Input.
    /// @return result whether the user has set Accepts Kyc Input

    function getOnlyAcceptsKycInput(address _identifiedAddress) public view override returns (bool result) {
        return onlyAcceptsKycInput[_identifiedAddress];
    }

    /// @param _identifiedAddress The public address to check.
    /// @dev Gets whether the user has set Accepts Kyc Input permanently (whether on or off).
    /// @return result whether the user has set Accepts Kyc Input permanently (whether on or off)

    function getOnlyAcceptsKycInputPermanently(address _identifiedAddress) public view override returns (bool result) {
        return lockOnlyAcceptsKycInputPermanently[_identifiedAddress];
    }

    //---------------- Token Upgrades ----------------//


    //****************************************************************************************************************//
    //@note: instead of explicitly returning, assign return value to variable  allows the code after the _;
    // in the mutex modifier to be run!
    //****************************************************************************************************************//

    /// @param _value The amount of tokens to upgrade.
    /// @dev Upgrades the user's tokens by sending them to the next contract (which will do the same). Sets auto upgrade for the user as well.
    /// @return result
    ///    | 3 = withdrew correctly
    ///    | 2 = could not withdraw
    ///    | 1 = not enough balance
    ///    | 0 = contract has not been updated

    function upgradeNativeTokens(uint256 _value) mutex public returns (uint256 result) {
        //check if it's been updated
        if (hasBeenUpdated == true) {
            //make sure the msg.sender has enough synthetic fuel to transfer
            if (balances[msg.sender][nativeBip32X_type] >= _value) {
                autoUpgradeEnabled[msg.sender] = true;

                //then proceed to send to address(this) to initiate the autoUpgrade
                // to the new contract.
                bool withdrawResult = withdrawToShyftKycContract(address(this), msg.sender, _value);
                if (withdrawResult == true) {
                    //withdrew correctly
                    result = 3;
                } else {
                    //could not withdraw
                    result = 2;
                }
            } else {
                //not enough balance
                result = 1;
            }
        } else {
            //contract has not been updated
            result = 0;
        }
    }

    /// @param _autoUpgrade Whether the tokens should be automatically upgraded when sent to this contract.
    /// @dev Sets auto upgrade for the message sender, for fallback functionality to upgrade tokens on receipt. The only reason a user would want to call this function is to modify behaviour *after* this contract has been updated, thus allowing choice.

    function setAutoUpgrade(bool _autoUpgrade) public {
        autoUpgradeEnabled[msg.sender] = _autoUpgrade;
    }

    //---------------- Native withdrawal / transfer functions ----------------//

    /// @param _to The destination payable address to send to.
    /// @param _value The amount of tokens to transfer.
    /// @dev Transfers native tokens (based on the current native Bip32X type, ex Shyft = 7341, Ethereum = 60) to the user's wallet.
    /// @notice 30k gas limit for transfers.
    /// @return ok
    ///    | true = tokens withdrawn properly to another erc223 contract
    ///    | false = the user does not have enough balance, or found a smart contract address instead of a payable address.

    function withdrawNative(address payable _to, uint256 _value) mutex public override returns (bool ok) {
        if (balances[msg.sender][nativeBip32X_type] >= _value) {
            uint codeLength;

            //retrieve the size of the code on target address, this needs assembly
            assembly {
                codeLength := extcodesize(_to)
            }

            //makes sure it's sending to a native (non-contract) address
            if (codeLength == 0) {
                balances[msg.sender][nativeBip32X_type] = balances[msg.sender][nativeBip32X_type].sub(_value);
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(_value);

                //@note: this is going to a regular account. the existing balance has already been reduced,
                // and as such the only thing to do is to send the actual Shyft fuel (or Ether, etc) to the
                // target address.

                _to.transfer(_value);

                emit EVT_WithdrawToAddress(msg.sender, _to, _value);
                ok = true;
            } else {
                ok = false;
            }
        } else {
            ok = false;
        }
    }

    /// @param _to The destination smart contract address to send to.
    /// @param _value The amount of tokens to transfer.
    /// @dev Transfers SHFT tokens to another external contract, using Erc223 mechanisms.
    /// @notice 30k gas limit for transfers.
    /// @return ok
    ///    | true = tokens withdrawn properly to another erc223 contract
    ///    | false = the user does not have enough balance, or not a smart contract address

    function withdrawToExternalContract(address _to, uint256 _value) mutex public override returns (bool ok) {
        if (balances[msg.sender][nativeBip32X_type] >= _value) {
            uint codeLength;
//            bytes memory empty;

            //retrieve the size of the code on target address, this needs assembly
            assembly {
                codeLength := extcodesize(_to)
            }

            //makes sure it's sending to a contract address
            if (codeLength == 0) {
                ok = false;
            } else {
                balances[msg.sender][nativeBip32X_type] = balances[msg.sender][nativeBip32X_type].sub(_value);
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(_value);

                //this will fail when sending to contracts with fallback functions that consume more than 20000 gas

                (bool success, ) = _to.call{value: _value, gas: 30000}("");

                IErc223ReceivingContract receiver = IErc223ReceivingContract(_to);
                bool fallbackSuccess = receiver.tokenFallback(msg.sender, _value, abi.encodePacked(shyftKycContractSig));

                if (success == true && fallbackSuccess == true) {
                    emit EVT_WithdrawToExternalContract(msg.sender, _to, _value);

                    ok = true;
                } else {
                    //@note:@here: needs revert() due to asset transactions already having occurred
                    revert();
                    //ok = false;
                }

            }
        } else {
            ok = false;
        }
    }

    /// @param _shyftKycContractAddress The address of the Shyft Kyc Contract that is being send to.
    /// @param _to The destination address to send to.
    /// @param _value The amount of tokens to transfer.
    /// @dev Transfers SHFT tokens to another Shyft Kyc contract.
    /// @notice 120k gas limit for transfers.
    /// @return ok
    ///    | true = tokens withdrawn properly to another Kyc Contract.
    ///    | false = the user does not have enough balance, or not a correct shyft contract address, or receiver only accepts kyc input.

    function withdrawToShyftKycContract(address _shyftKycContractAddress, address _to, uint256 _value) mutex public override returns (bool ok) {
        if (balances[msg.sender][nativeBip32X_type] >= _value) {
            uint codeLength;

            //retrieve the size of the code on target address, this needs assembly
            assembly {
                codeLength := extcodesize(_shyftKycContractAddress)
            }

            //makes sure it's sending to a contract address
            if (codeLength == 0) {
                // not a smart contract
                ok = false;
            } else {
                balances[msg.sender][nativeBip32X_type] = balances[msg.sender][nativeBip32X_type].sub(_value);
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(_value);

                IShyftKycContract receivingShyftKycContract = IShyftKycContract(_shyftKycContractAddress);

                if (receivingShyftKycContract.getOnlyAcceptsKycInput(_to) == false) {
                    // sending to ShyftKycContracts only; migrateFromKycContract uses ~75830 - 21000 gas to execute,
                    // with a registry lookup. Adding 50k more just in case there are other checks in the v2.
                    if (receivingShyftKycContract.migrateFromKycContract{gas: 120000, value: _value}(_to) == false) {
                        revert();
                    }

                    emit EVT_WithdrawToShyftKycContract(msg.sender, _to, _value);

                    ok = true;
                } else {
                    // receiver only accepts kyc input
                    ok = false;
                }
            }
        } else {
            ok = false;
        }
    }

    //---------------- ERC 223 receiver ----------------//

    /// @param _from The address of the origin.
    /// @param _value The address of the recipient.
    /// @param _data The bytes data of any ERC223 transfer function.
    /// @dev Transfers assets to destination, with ERC20 functionality. (basic ERC20 functionality, but blocks transactions if Only Accepts Kyc Input is set to true.)
    /// @return ok returns true if the checks pass and there are enough allowed + actual tokens to transfer to the recipient.

    function tokenFallback(address _from, uint _value, bytes memory _data) mutex public override returns (bool ok) {
        // block transfers if the recipient only allows kyc input, check other factors
        require(onlyAcceptsKycInput[_from] == false);


        IShyftKycContractRegistry contractRegistry = IShyftKycContractRegistry(shyftKycContractRegistryAddress);

        // if kyc registry exists, check if only using a known kyc contract communication cycle, then verify the message
        // sender is a kyc contract.
        if (shyftKycContractRegistryAddress != address(0) && contractRegistry.isShyftKycContract(address(msg.sender)) == true) {
            revert("cannot process fallback from Shyft Kyc Contract in this version of Shyft Core");
        }

        uint256 bip32X_type;

        bytes4 tokenSig;

        //make sure we have enough bytes to determine a signature
        if (_data.length >= 4) {
            tokenSig = bytes4(uint32(bytes4(bytes1(_data[3])) >> 24) + uint32(bytes4(bytes1(_data[2])) >> 16) + uint32(bytes4(bytes1(_data[1])) >> 8) + uint32(bytes4(bytes1(_data[0]))));
        }

        //@note: for token indexing, we use higher range addressable space (256 bit integer).
        // this guarantees practically infinite indexes.
        //@note: using msg.sender in the keccak hash since msg.sender in this case (should) be the
        // contract itself (and allowing this to be passed in, instead of using msg.sender, does not
        // suffice as any contract could then call this fallback.)
        //
        // thus, this fallback will not function properly with abstracted synthetics.
        bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, msg.sender)));
        balances[_from][bip32X_type] = balances[_from][bip32X_type].add(_value);

        emit EVT_Bip32X_TypeTokenFallback(msg.sender, _from, _value, nativeBip32X_type, bip32X_type);
        emit EVT_TransferAndMintBip32X_type(msg.sender, _from, _value, bip32X_type);

        ok = true;

        if (ok == true) {
            emit EVT_Erc223TokenFallback(_from, _value, _data);
        }
    }

    //---------------- ERC 223/20 ----------------//

    /// @param _who The address of the user.
    /// @dev Gets the balance for the SHFT token type for a specific user.
    /// @return the balance of the SHFT token type for the user

    function balanceOf(address _who) public view override returns (uint) {
        return balances[_who][ShyftTokenType];
    }

    /// @dev Gets the name of the token.
    /// @return _name of the token.

    function name() public pure returns (string memory _name) {
        return "Shyft [ Byfrost ]";
    }

    /// @dev Gets the symbol of the token.
    /// @return _symbol the symbol of the token

    function symbol() public pure returns (string memory _symbol) {
        //@note: "SFT" is the 3 letter variant
        return "SHFT";
    }

    /// @dev Gets the number of decimals of the token.
    /// @return _decimals number of decimals of the token.

    function decimals() public pure returns (uint8 _decimals) {
        return 18;
    }

    /// @dev Gets the number of SHFT tokens available.
    /// @return result total supply of SHFT tokens

    function totalSupply() public view override returns (uint256 result) {
        return getTotalSupplyBip32X(ShyftTokenType);
    }

    /// @param _to The address of the origin.
    /// @param _value The address of the recipient.
    /// @dev Transfers assets to destination, with ERC20 functionality. (basic ERC20 functionality, but blocks transactions if Only Accepts Kyc Input is set to true.)
    /// @return ok returns true if the checks pass and there are enough allowed + actual tokens to transfer to the recipient.

    function transfer(address _to, uint256 _value) public override returns (bool ok) {
        // block transfers if the recipient only allows kyc input, check other factors
        if (onlyAcceptsKycInput[_to] == false && balances[msg.sender][ShyftTokenType] >= _value) {
            balances[msg.sender][ShyftTokenType] = balances[msg.sender][ShyftTokenType].sub(_value);

            balances[_to][ShyftTokenType] = balances[_to][ShyftTokenType].add(_value);

            emit Transfer(msg.sender, _to, _value);

            return true;
        } else {
            return false;
        }
    }

    /// @param _to The address of the origin.
    /// @param _value The address of the recipient.
    /// @param _data The bytes data of any ERC223 transfer function.
    /// @dev Transfers assets to destination, with ERC223 functionality. (basic ERC223 functionality, but blocks transactions if Only Accepts Kyc Input is set to true.)
    /// @return ok returns true if the checks pass and there are enough allowed + actual tokens to transfer to the recipient.

    function transfer(address _to, uint _value, bytes memory _data) mutex public override returns (bool ok) {
        // block transfers if the recipient only allows kyc input, check other factors
        if (onlyAcceptsKycInput[_to] == false && balances[msg.sender][ShyftTokenType] >= _value) {
            uint codeLength;

            //retrieve the size of the code on target address, this needs assembly
            assembly {
                codeLength := extcodesize(_to)
            }

            balances[msg.sender][ShyftTokenType] = balances[msg.sender][ShyftTokenType].sub(_value);

            balances[_to][ShyftTokenType] = balances[_to][ShyftTokenType].add(_value);


            if (codeLength > 0) {
                IErc223ReceivingContract receiver = IErc223ReceivingContract(_to);
                if (receiver.tokenFallback(msg.sender, _value, _data) == true) {
                    ok = true;
                } else {
                    //@note: must revert() due to asset transactions already having occurred.
                    revert();
                }
            } else {
                ok = true;
            }
        }

        if (ok == true) {
            emit Transfer(msg.sender, _to, _value, _data);
        }
    }

    /// @param _tokenOwner The address of the origin.
    /// @param _spender The address of the recipient.
    /// @dev Get the current allowance for the basic Shyft token type. (basic ERC20 functionality)
    /// @return remaining the current allowance for the basic Shyft token type for a specific user

    function allowance(address _tokenOwner, address _spender) public view override returns (uint remaining) {
       return allowed[_tokenOwner][_spender][ShyftTokenType];
    }


    /// @param _spender The address of the recipient.
    /// @param _tokens The amount of tokens to transfer.
    /// @dev Allows pre-approving assets to be sent to a participant. (basic ERC20 functionality)
    /// @notice This (standard) function known to have an issue.
    /// @return success whether the approve function completed successfully

    function approve(address _spender, uint _tokens) public override returns (bool success) {
        allowed[msg.sender][_spender][ShyftTokenType] = _tokens;

        //example of issue:
        //user a has 20 tokens allowed from zero :: no incentive to frontrun
        //user a has +2 tokens allowed from 20 :: frontrunning would deplete 20 and add 2 :: incentive there.

        emit Approval(msg.sender, _spender, _tokens);

        return true;
    }

    /// @param _from The address of the origin.
    /// @param _to The address of the recipient.
    /// @param _tokens The amount of tokens to transfer.
    /// @dev Performs the withdrawal of pre-approved assets. (basic ERC20 functionality, but blocks transactions if Only Accepts Kyc Input is set to true.)
    /// @return success returns true if the checks pass and there are enough allowed + actual tokens to transfer to the recipient.

    function transferFrom(address _from, address _to, uint _tokens) public override returns (bool success) {
        // block transfers if the recipient only allows kyc input, check other factors
        if (onlyAcceptsKycInput[_to] == false && allowed[_from][msg.sender][ShyftTokenType] >= _tokens && balances[_from][ShyftTokenType] >= _tokens) {
            allowed[_from][msg.sender][ShyftTokenType] = allowed[_from][msg.sender][ShyftTokenType].sub(_tokens);

            balances[_from][ShyftTokenType] = balances[_from][ShyftTokenType].sub(_tokens);
            balances[_to][ShyftTokenType] = balances[_to][ShyftTokenType].add(_tokens);

            emit Transfer(_from, _to, _tokens);

            return true;
        } else {
            return false;
        }
    }

    //---------------- Shyft Token Transfer [KycContract] ----------------//

    /// @param _to The address of the recipient.
    /// @param _value The amount of tokens to transfer.
    /// @param _bip32X_type The Bip32X type of the asset to transfer.
    /// @dev | Transfers assets from one Shyft user to another, with restrictions on the transfer if the recipient has enabled Only Accept KYC Input.
    /// @return result returns true if the transaction completes, reverts if it does not.

    function transferBip32X_type(address _to, uint256 _value, uint256 _bip32X_type) public returns (bool result) {
        // block transfers if the recipient only allows kyc input
        require(onlyAcceptsKycInput[_to] == false);
        require(balances[msg.sender][_bip32X_type] >= _value);

        balances[msg.sender][_bip32X_type] = balances[msg.sender][_bip32X_type].sub(_value);
        balances[_to][_bip32X_type] = balances[_to][_bip32X_type].add(_value);

        emit EVT_TransferBip32X_type(msg.sender, _to, _value, _bip32X_type);
        return true;
    }

    //---------------- Shyft Token Transfer [Erc223] ----------------//

    /// @param _erc223ContractAddress The address of the ERC223 contract that
    /// @param _to The address of the recipient.
    /// @param _value The amount of tokens to transfer.
    /// @dev | Withdraws a Bip32X type Shyft synthetic asset into its origin ERC223 contract. Burns the current synthetic balance.
    ///      | Cannot withdraw Bip32X type into an incorrect destination contract (as the hash will not match).
    /// @return ok returns true if the transaction completes, reverts if it does not

    function withdrawTokenBip32X_typeToErc223(address _erc223ContractAddress, address _to, uint256 _value) mutex public returns (bool ok) {
        uint256 bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, _erc223ContractAddress)));

        require(balances[msg.sender][bip32X_type] >= _value);

        bytes memory empty;

        balances[msg.sender][bip32X_type] = balances[msg.sender][bip32X_type].sub(_value);

        bytes4 sig = bytes4(keccak256(abi.encodePacked("transfer(address,uint256,bytes)")));
        (bool success, ) = _erc223ContractAddress.call(abi.encodeWithSelector(sig, _to, _value, empty));

        IErc223ReceivingContract receiver = IErc223ReceivingContract(_erc223ContractAddress);
        bool fallbackSuccess = receiver.tokenFallback(msg.sender, _value, empty);

        if (fallbackSuccess == true && success == true) {
            emit EVT_TransferAndBurnBip32X_type(_erc223ContractAddress, msg.sender, _to, _value, bip32X_type);

            ok = true;
        } else {
            //@note: reverts since a transactional event has occurred.
            revert();
        }
    }

    //---------------- Shyft Token Transfer [Erc20] ----------------//

    /// @param _erc20ContractAddress The address of the ERC20 contract that
    /// @param _value The amount of tokens to transfer.
    /// @dev | Transfers assets from any Erc20 contract to a Bip32X type Shyft synthetic asset. Mints the current synthetic balance.
    /// @return ok returns true if the transaction completes, reverts if it does not

    function transferFromErc20Token(address _erc20ContractAddress, uint256 _value) mutex public returns (bool ok) {
        require(_erc20ContractAddress != address(this));

        // block transfers if the recipient only allows kyc input, check other factors
        require(onlyAcceptsKycInput[msg.sender] == false);

        IErc20 erc20Contract = IErc20(_erc20ContractAddress);

        if (erc20Contract.allowance(msg.sender, address(this)) >= _value) {
            bool transferFromResult = erc20Contract.transferFrom(msg.sender, address(this), _value);

            if (transferFromResult == true) {
                //@note: using _erc20ContractAddress in the keccak hash since _erc20ContractAddress will be where
                // the tokens are created and managed.
                //
                // thus, this fallback will not function properly with abstracted synthetics (including this contract)
                // hence the initial require() check above to prevent this behaviour.

                uint256 bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, _erc20ContractAddress)));
                balances[msg.sender][bip32X_type] = balances[msg.sender][bip32X_type].add(_value);

                emit EVT_TransferAndMintBip32X_type(_erc20ContractAddress, msg.sender, _value, bip32X_type);

                //transfer successful
                ok = true;
            } else {
                //@note: reverts since a transactional event has occurred.
                revert();
            }
        } else {
            //not enough allowance
        }
    }

    /// @param _erc20ContractAddress The address of the ERC20 contract that
    /// @param _to The address of the recipient.
    /// @param _value The amount of tokens to transfer.
    /// @dev | Withdraws a Bip32X type Shyft synthetic asset into its origin ERC20 contract. Burns the current synthetic balance.
    ///      | Cannot withdraw Bip32X type into an incorrect destination contract (as the hash will not match).
    /// @return ok returns true if the transaction completes, reverts if it does not

    function withdrawTokenBip32X_typeToErc20(address _erc20ContractAddress, address _to, uint256 _value) mutex public returns (bool ok) {
        uint256 bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, _erc20ContractAddress)));

        require(balances[msg.sender][bip32X_type] >= _value);

        balances[msg.sender][bip32X_type] = balances[msg.sender][bip32X_type].sub(_value);

        bytes4 sig = bytes4(keccak256(abi.encodePacked("transfer(address,uint256)")));
        (bool success, ) = _erc20ContractAddress.call(abi.encodeWithSelector(sig, _to, _value));

        if (success == true) {
            emit EVT_TransferAndBurnBip32X_type(_erc20ContractAddress, msg.sender, _to, _value, bip32X_type);

            ok = true;
        } else {
            //@note: reverts since a transactional event has occurred.
            revert();
        }
    }
}