// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {NonReceivableInitializedProxy} from "./NonReceivableInitializedProxy.sol";
import {PartyBuy} from "./PartyBuy.sol";
import {Structs} from "./Structs.sol";

/**
 * @title PartyBuy Factory
 * @author Anna Carroll
 */
contract PartyBuyFactory {
    //======== Events ========

    event PartyBuyDeployed(
        address partyProxy,
        address creator,
        address nftContract,
        uint256 tokenId,
        uint256 maxPrice,
        uint256 secondsToTimeout,
        address splitRecipient,
        uint256 splitBasisPoints,
        address gatedToken,
        uint256 gatedTokenAmount,
        string name,
        string symbol
    );

    //======== Immutable storage =========

    address public immutable logic;
    address public immutable partyDAOMultisig;
    address public immutable tokenVaultFactory;
    address public immutable weth;

    //======== Mutable storage =========

    // PartyBid proxy => block number deployed at
    mapping(address => uint256) public deployedAt;

    //======== Constructor =========

    constructor(
        address _partyDAOMultisig,
        address _tokenVaultFactory,
        address _weth,
        address _allowList
    ) {
        partyDAOMultisig = _partyDAOMultisig;
        tokenVaultFactory = _tokenVaultFactory;
        weth = _weth;
        // deploy logic contract
        PartyBuy _logicContract = new PartyBuy(_partyDAOMultisig, _tokenVaultFactory, _weth, _allowList);
        // store logic contract address
        logic = address(_logicContract);
    }

    //======== Deploy function =========

    function startParty(
        address _nftContract,
        uint256 _tokenId,
        uint256 _maxPrice,
        uint256 _secondsToTimeout,
        Structs.AddressAndAmount calldata _split,
        Structs.AddressAndAmount calldata _tokenGate,
        string memory _name,
        string memory _symbol
    ) external returns (address partyBuyProxy) {
        bytes memory _initializationCalldata =
            abi.encodeWithSelector(
            PartyBuy.initialize.selector,
            _nftContract,
            _tokenId,
            _maxPrice,
            _secondsToTimeout,
            _split,
            _tokenGate,
            _name,
            _symbol
        );

        partyBuyProxy = address(
            new NonReceivableInitializedProxy(
                logic,
                _initializationCalldata
            )
        );

        deployedAt[partyBuyProxy] = block.number;

        emit PartyBuyDeployed(
            partyBuyProxy,
            msg.sender,
            _nftContract,
            _tokenId,
            _maxPrice,
            _secondsToTimeout,
            _split.addr,
            _split.amount,
            _tokenGate.addr,
            _tokenGate.amount,
            _name,
            _symbol
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
 * @title NonReceivableInitializedProxy
 * @author Anna Carroll
 */
contract NonReceivableInitializedProxy {
    // address of logic contract
    address public immutable logic;

    // ======== Constructor =========

    constructor(
        address _logic,
        bytes memory _initializationCalldata
    ) {
        logic = _logic;
        // Delegatecall into the logic contract, supplying initialization calldata
        (bool _ok, bytes memory returnData) =
            _logic.delegatecall(_initializationCalldata);
        // Revert if delegatecall to implementation reverts
        require(_ok, string(returnData));
    }

    // ======== Fallback =========

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }
}

/*
                   ___                    _       _  _    ___     ___     ___
                  | _ \  __ _      _ _   | |_    | || |  |   \   /   \   / _ \
   ~~~~ ____      |  _/ / _` |    | '_|  |  _|    \_, |  | |) |  | - |  | (_) |
  Y_,___|[]|     _|_|_  \__,_|   _|_|_   _\__|   _|__/   |___/   |_|_|   \___/
 {|_|_|_|[]|_,__| """ |_|"""""|_|"""""|_|"""""|_| """"|_|"""""|_|"""""|_|"""""|
//oo---OO=OO".  `-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'

Anna Carroll for PartyDAO
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// ============ External Imports: External Contracts & Contract Interfaces ============
import {Party} from "./Party.sol";
import {Structs} from "./Structs.sol";
import {IAllowList} from "./IAllowList.sol";

contract PartyBuy is Party {
    // partyStatus Transitions:
    //   (1) PartyStatus.ACTIVE on deploy
    //   (2) PartyStatus.WON after successful buy()
    //   (3) PartyStatus.LOST after successful expire()

    // ============ Internal Constants ============

    // PartyBuy version 1
    uint16 public constant VERSION = 1;

    // ============ Immutables ============

    IAllowList public immutable allowList;

    // ============ Public Not-Mutated Storage ============

    // the timestamp at which the Party is no longer active
    uint256 public expiresAt;
    // the maximum price that the party is willing to
    // spend on the token
    // NOTE: the party can accept *UP TO* 102.5% of maxPrice in total,
    // and will not accept more contributions after this
    uint256 public maxPrice;

    // ============ Events ============

    // emitted when the token is successfully bought
    event Bought(address triggeredBy, address targetAddress, uint256 ethSpent, uint256 ethFeePaid, uint256 totalContributed);

    // emitted if the Party fails to buy the token before expiresAt
    // and someone expires the Party so folks can reclaim ETH
    event Expired(address triggeredBy);

    // ======== Constructor =========

    constructor(
        address _partyDAOMultisig,
        address _tokenVaultFactory,
        address _weth,
        address _allowList
    ) Party(_partyDAOMultisig, _tokenVaultFactory, _weth) {
        allowList = IAllowList(_allowList);
    }

    // ======== Initializer =========

    function initialize(
        address _nftContract,
        uint256 _tokenId,
        uint256 _maxPrice,
        uint256 _secondsToTimeout,
        Structs.AddressAndAmount calldata _split,
        Structs.AddressAndAmount calldata _tokenGate,
        string memory _name,
        string memory _symbol
    ) external initializer {
        // validate maxPrice
        require(_maxPrice > 0, "PartyBuy::initialize: must set price higher than 0");
        // initialize & validate shared Party variables
        __Party_init(_nftContract, _tokenId, _split, _tokenGate, _name, _symbol);
        // set PartyBuy-specific state variables
        expiresAt = block.timestamp + _secondsToTimeout;
        maxPrice = _maxPrice;
    }

    // ======== External: Contribute =========

    /**
     * @notice Contribute to the Party's treasury
     * while the Party is still active
     * @dev Emits a Contributed event upon success; callable by anyone
     */
    function contribute() external payable nonReentrant {
        // require that the new total contributed is not greater than
        // the maximum amount the Party is willing to spend
        require(totalContributedToParty + msg.value <= getMaximumContributions(), "PartyBuy::contribute: cannot contribute more than max");
        // continue with shared _contribute flow
        _contribute();
    }

    // ======== External: Buy =========

    /**
     * @notice Buy the token by calling targetContract with calldata supplying value
     * @dev Emits a Bought event upon success; reverts otherwise. callable by anyone
     */
    function buy(uint256 _value, address _targetContract, bytes calldata _calldata) external nonReentrant {
        require(
            partyStatus == PartyStatus.ACTIVE,
            "PartyBuy::buy: party not active"
        );
        // ensure the target contract is on allow list
        require(allowList.allowed(_targetContract), "PartyBuy::buy: targetContract not on AllowList");
        // check that value is not zero (else, token will be burned in TokenVault)
        require(_value > 0, "PartyBuy::buy: can't spend zero");
        // check that value is not more than the maximum price set at deploy time
        require(_value <= maxPrice, "PartyBuy::buy: can't spend over max price");
        // check that value is not more than
        // the maximum amount the party can spend while paying ETH fee
        require(_value <= getMaximumSpend(), "PartyBuy::buy: insuffucient funds to buy token plus fee");
        // require that the NFT is NOT owned by the Party
        require(_getOwner() != address(this), "PartyBuy::buy: own token before call");
        // execute the calldata on the target contract
        (bool _success, bytes memory _returnData) = address(_targetContract).call{value: _value}(_calldata);
        // require that the external call succeeded
        require(_success, string(_returnData));
        // require that the NFT is owned by the Party
        require(_getOwner() == address(this), "PartyBuy::buy: failed to buy token");
        // set partyStatus to WON
        partyStatus = PartyStatus.WON;
        // record totalSpent,
        // send ETH fees to PartyDAO,
        // fractionalize the Token
        // send Token fees to PartyDAO & split proceeds to split recipient
        uint256 _ethFee = _closeSuccessfulParty(_value);
        // emit Bought event
        emit Bought(msg.sender, _targetContract, _value, _ethFee, totalContributedToParty);
    }

    // ======== External: Fail =========

    /**
     * @notice If the token couldn't be successfully bought
      * within the specified period of time, move to FAILED state
      * so users can reclaim their funds.
     * @dev Emits a Expired event upon finishing; reverts otherwise.
     * callable by anyone after expiresAt
     */
    function expire() external nonReentrant {
        require(
            partyStatus == PartyStatus.ACTIVE,
            "PartyBuy::expire: party not active"
        );
        require(expiresAt <= block.timestamp, "PartyBuy::expire: party has not timed out");
        // set partyStatus to LOST
        partyStatus = PartyStatus.LOST;
        // emit Expired event
        emit Expired(msg.sender);
    }

    // ============ Internal ============

    /**
    * @notice Get the maximum amount that can be contributed to the Party
    * @return _maxContributions the maximum amount that can be contributed to the party
    */
    function getMaximumContributions() public view returns (uint256 _maxContributions) {
        uint256 _price = maxPrice;
        _maxContributions = _price + _getEthFee(_price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface Structs {
    struct AddressAndAmount {
        address addr;
        uint256 amount;
    }
}

/*
__/\\\\\\\\\\\\\_____________________________________________________________/\\\\\\\\\\\\________/\\\\\\\\\__________/\\\\\______
 _\/\\\/////////\\\__________________________________________________________\/\\\////////\\\____/\\\\\\\\\\\\\______/\\\///\\\____
  _\/\\\_______\/\\\__________________________________/\\\_________/\\\__/\\\_\/\\\______\//\\\__/\\\/////////\\\___/\\\/__\///\\\__
   _\/\\\\\\\\\\\\\/___/\\\\\\\\\_____/\\/\\\\\\\___/\\\\\\\\\\\___\//\\\/\\\__\/\\\_______\/\\\_\/\\\_______\/\\\__/\\\______\//\\\_
    _\/\\\/////////____\////////\\\___\/\\\/////\\\_\////\\\////_____\//\\\\\___\/\\\_______\/\\\_\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_
     _\/\\\_______________/\\\\\\\\\\__\/\\\___\///_____\/\\\__________\//\\\____\/\\\_______\/\\\_\/\\\/////////\\\_\//\\\______/\\\__
      _\/\\\______________/\\\/////\\\__\/\\\____________\/\\\_/\\___/\\_/\\\_____\/\\\_______/\\\__\/\\\_______\/\\\__\///\\\__/\\\____
       _\/\\\_____________\//\\\\\\\\/\\_\/\\\____________\//\\\\\___\//\\\\/______\/\\\\\\\\\\\\/___\/\\\_______\/\\\____\///\\\\\/_____
        _\///_______________\////////\//__\///______________\/////_____\////________\////////////_____\///________\///_______\/////_______

Anna Carroll for PartyDAO
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// ============ External Imports: Inherited Contracts ============
// NOTE: we inherit from OpenZeppelin upgradeable contracts
// because of the proxy structure used for cheaper deploys
// (the proxies are NOT actually upgradeable)
import {
ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
ERC721HolderUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
// ============ External Imports: External Contracts & Contract Interfaces ============
import {
IERC721VaultFactory
} from "./external/interfaces/IERC721VaultFactory.sol";
import {ITokenVault} from "./external/interfaces/ITokenVault.sol";
import {IWETH} from "./external/interfaces/IWETH.sol";
import {
IERC721Metadata
} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {
IERC20
} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// ============ Internal Imports ============
import {Structs} from "./Structs.sol";

contract Party is ReentrancyGuardUpgradeable, ERC721HolderUpgradeable {
    // ============ Enums ============

    // State Transitions:
    //   (0) ACTIVE on deploy
    //   (1) WON if the Party has won the token
    //   (2) LOST if the Party is over & did not win the token
    enum PartyStatus {ACTIVE, WON, LOST}

    // ============ Structs ============

    struct Contribution {
        uint256 amount;
        uint256 previousTotalContributedToParty;
    }

    // ============ Internal Constants ============

    // tokens are minted at a rate of 1 ETH : 1000 tokens
    uint16 internal constant TOKEN_SCALE = 1000;
    // PartyDAO receives an ETH fee equal to 2.5% of the amount spent
    uint16 internal constant ETH_FEE_BASIS_POINTS = 250;
    // PartyDAO receives a token fee equal to 2.5% of the total token supply
    uint16 internal constant TOKEN_FEE_BASIS_POINTS = 250;
    // token is relisted on Fractional with an
    // initial reserve price equal to 2x the price of the token
    uint8 internal constant RESALE_MULTIPLIER = 2;

    // ============ Immutables ============

    address public immutable partyFactory;
    address public immutable partyDAOMultisig;
    IERC721VaultFactory public immutable tokenVaultFactory;
    IWETH public immutable weth;

    // ============ Public Not-Mutated Storage ============

    // NFT contract
    IERC721Metadata public nftContract;
    // ID of token within NFT contract
    uint256 public tokenId;
    // Fractionalized NFT vault responsible for post-purchase experience
    ITokenVault public tokenVault;
    // the address that will receive a portion of the tokens
    // if the Party successfully buys the token
    address public splitRecipient;
    // percent of the total token supply
    // taken by the splitRecipient
    uint256 public splitBasisPoints;
    // address of token that users need to hold to contribute
    // address(0) if party is not token gated
    IERC20 public gatedToken;
    // amount of token that users need to hold to contribute
    // 0 if party is not token gated
    uint256 public gatedTokenAmount;
    // ERC-20 name and symbol for fractional tokens
    string public name;
    string public symbol;

    // ============ Public Mutable Storage ============

    // state of the contract
    PartyStatus public partyStatus;
    // total ETH deposited by all contributors
    uint256 public totalContributedToParty;
    // the total spent buying the token;
    // 0 if the NFT is not won; price of token + 2.5% PartyDAO fee if NFT is won
    uint256 public totalSpent;
    // contributor => array of Contributions
    mapping(address => Contribution[]) public contributions;
    // contributor => total amount contributed
    mapping(address => uint256) public totalContributed;
    // contributor => true if contribution has been claimed
    mapping(address => bool) public claimed;

    // ============ Events ============

    event Contributed(
        address indexed contributor,
        uint256 amount,
        uint256 previousTotalContributedToParty,
        uint256 totalFromContributor
    );

    event Claimed(
        address indexed contributor,
        uint256 totalContributed,
        uint256 excessContribution,
        uint256 tokenAmount
    );

    // ======== Modifiers =========

    modifier onlyPartyDAO() {
        require(
            msg.sender == partyDAOMultisig,
            "Party:: only PartyDAO multisig"
        );
        _;
    }

    // ======== Constructor =========

    constructor(
        address _partyDAOMultisig,
        address _tokenVaultFactory,
        address _weth
    ) {
        partyFactory = msg.sender;
        partyDAOMultisig = _partyDAOMultisig;
        tokenVaultFactory = IERC721VaultFactory(_tokenVaultFactory);
        weth = IWETH(_weth);
    }

    // ======== Internal: Initialize =========

    function __Party_init(
        address _nftContract,
        uint256 _tokenId,
        Structs.AddressAndAmount calldata _split,
        Structs.AddressAndAmount calldata _tokenGate,
        string memory _name,
        string memory _symbol
    ) internal {
        require(msg.sender == partyFactory, "Party::__Party_init: only factory can init");
        // validate token exists (must set nftContract & tokenId before _getOwner)
        nftContract = IERC721Metadata(_nftContract);
        tokenId = _tokenId;
        require(_getOwner() != address(0), "Party::__Party_init: NFT getOwner failed");
        // if split is non-zero,
        if (_split.addr != address(0) && _split.amount != 0) {
            // validate that party split won't retain the total token supply
            uint256 _remainingBasisPoints = 10000 - TOKEN_FEE_BASIS_POINTS;
            require(_split.amount < _remainingBasisPoints, "Party::__Party_init: basis points can't take 100%");
            splitBasisPoints = _split.amount;
            splitRecipient = _split.addr;
        }
        // if token gating is non-zero
        if (_tokenGate.addr != address(0) && _tokenGate.amount != 0) {
            // call totalSupply to verify that address is ERC-20 token contract
            IERC20(_tokenGate.addr).totalSupply();
            gatedToken = IERC20(_tokenGate.addr);
            gatedTokenAmount = _tokenGate.amount;
        }
        // initialize ReentrancyGuard and ERC721Holder
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        // set storage variables
        name = _name;
        symbol = _symbol;
    }

    // ======== Internal: Contribute =========

    /**
     * @notice Contribute to the Party's treasury
     * while the Party is still active
     * @dev Emits a Contributed event upon success; callable by anyone
     */
    function _contribute() internal {
        require(
            partyStatus == PartyStatus.ACTIVE,
            "Party::contribute: party not active"
        );
        address _contributor = msg.sender;
        uint256 _amount = msg.value;
        // if token gated, require that contributor has balance of gated tokens
        if (address(gatedToken) != address(0)) {
            require(gatedToken.balanceOf(_contributor) >= gatedTokenAmount, "Party::contribute: must hold tokens to contribute");
        }
        require(_amount > 0, "Party::contribute: must contribute more than 0");
        // get the current contract balance
        uint256 _previousTotalContributedToParty = totalContributedToParty;
        // add contribution to contributor's array of contributions
        Contribution memory _contribution =
            Contribution({
                amount: _amount,
                previousTotalContributedToParty: _previousTotalContributedToParty
            });
        contributions[_contributor].push(_contribution);
        // add to contributor's total contribution
        totalContributed[_contributor] = totalContributed[_contributor] + _amount;
        // add to party's total contribution & emit event
        totalContributedToParty = _previousTotalContributedToParty + _amount;
        emit Contributed(
            _contributor,
            _amount,
            _previousTotalContributedToParty,
            totalContributed[_contributor]
        );
    }

    // ======== External: Claim =========

    /**
     * @notice Claim the tokens and excess ETH owed
     * to a single contributor after the party has ended
     * @dev Emits a Claimed event upon success
     * callable by anyone (doesn't have to be the contributor)
     * @param _contributor the address of the contributor
     */
    function claim(address _contributor) external nonReentrant {
        // ensure party has finalized
        require(
            partyStatus != PartyStatus.ACTIVE,
            "Party::claim: party not finalized"
        );
        // ensure contributor submitted some ETH
        require(
            totalContributed[_contributor] != 0,
            "Party::claim: not a contributor"
        );
        // ensure the contributor hasn't already claimed
        require(
            !claimed[_contributor],
            "Party::claim: contribution already claimed"
        );
        // mark the contribution as claimed
        claimed[_contributor] = true;
        // calculate the amount of fractional NFT tokens owed to the user
        // based on how much ETH they contributed towards the party,
        // and the amount of excess ETH owed to the user
        (uint256 _tokenAmount, uint256 _ethAmount) =
        getClaimAmounts(_contributor);
        // transfer tokens to contributor for their portion of ETH used
        _transferTokens(_contributor, _tokenAmount);
        // if there is excess ETH, send it back to the contributor
        _transferETHOrWETH(_contributor, _ethAmount);
        emit Claimed(
            _contributor,
            totalContributed[_contributor],
            _ethAmount,
            _tokenAmount
        );
    }

    // ======== External: Emergency Escape Hatches (PartyDAO Multisig Only) =========

    /**
     * @notice Escape hatch: in case of emergency,
     * PartyDAO can use emergencyWithdrawEth to withdraw
     * ETH stuck in the contract
     */
    function emergencyWithdrawEth(uint256 _value)
        external
        onlyPartyDAO
    {
        _transferETHOrWETH(partyDAOMultisig, _value);
    }

    /**
     * @notice Escape hatch: in case of emergency,
     * PartyDAO can use emergencyCall to call an external contract
     * (e.g. to withdraw a stuck NFT or stuck ERC-20s)
     */
    function emergencyCall(address _contract, bytes memory _calldata)
        external
        onlyPartyDAO
        returns (bool _success, bytes memory _returnData)
    {
        (_success, _returnData) = _contract.call(_calldata);
        require(_success, string(_returnData));
    }

    /**
     * @notice Escape hatch: in case of emergency,
     * PartyDAO can force the Party to finalize with status LOST
     * (e.g. if finalize is not callable)
     */
    function emergencyForceLost()
        external
        onlyPartyDAO
    {
        // set partyStatus to LOST
        partyStatus = PartyStatus.LOST;
    }

    // ======== Public: Utility Calculations =========

    /**
     * @notice Convert ETH value to equivalent token amount
     */
    function valueToTokens(uint256 _value)
        public
        pure
        returns (uint256 _tokens)
    {
        _tokens = _value * TOKEN_SCALE;
    }

    /**
     * @notice The maximum amount that can be spent by the Party
     * while paying the ETH fee to PartyDAO
     * @return _maxSpend the maximum spend
     */
    function getMaximumSpend() public view returns (uint256 _maxSpend) {
        _maxSpend = (totalContributedToParty * 10000) / (10000 + ETH_FEE_BASIS_POINTS);
    }

    /**
     * @notice Calculate the amount of fractional NFT tokens owed to the contributor
     * based on how much ETH they contributed towards buying the token,
     * and the amount of excess ETH owed to the contributor
     * based on how much ETH they contributed *not* used towards buying the token
     * @param _contributor the address of the contributor
     * @return _tokenAmount the amount of fractional NFT tokens owed to the contributor
     * @return _ethAmount the amount of excess ETH owed to the contributor
     */
    function getClaimAmounts(address _contributor)
        public
        view
        returns (uint256 _tokenAmount, uint256 _ethAmount)
    {
        require(partyStatus != PartyStatus.ACTIVE, "Party::getClaimAmounts: party still active; amounts undetermined");
        uint256 _totalContributed = totalContributed[_contributor];
        if (partyStatus == PartyStatus.WON) {
            // calculate the amount of this contributor's ETH
            // that was used to buy the token
            uint256 _totalEthUsed = totalEthUsed(_contributor);
            if (_totalEthUsed > 0) {
                _tokenAmount = valueToTokens(_totalEthUsed);
            }
            // the rest of the contributor's ETH should be returned
            _ethAmount = _totalContributed - _totalEthUsed;
        } else {
            // if the token wasn't bought, no ETH was spent;
            // all of the contributor's ETH should be returned
            _ethAmount = _totalContributed;
        }
    }

    /**
     * @notice Calculate the total amount of a contributor's funds
     * that were used towards the buying the token
     * @dev always returns 0 until the party has been finalized
     * @param _contributor the address of the contributor
     * @return _total the sum of the contributor's funds that were
     * used towards buying the token
     */
    function totalEthUsed(address _contributor)
        public
        view
        returns (uint256 _total)
    {
        require(partyStatus != PartyStatus.ACTIVE, "Party::totalEthUsed: party still active; amounts undetermined");
        // load total amount spent once from storage
        uint256 _totalSpent = totalSpent;
        // get all of the contributor's contributions
        Contribution[] memory _contributions = contributions[_contributor];
        for (uint256 i = 0; i < _contributions.length; i++) {
            // calculate how much was used from this individual contribution
            uint256 _amount = _ethUsed(_totalSpent, _contributions[i]);
            // if we reach a contribution that was not used,
            // no subsequent contributions will have been used either,
            // so we can stop calculating to save some gas
            if (_amount == 0) break;
            _total = _total + _amount;
        }
    }

    // ============ Internal ============

    function _closeSuccessfulParty(uint256 _nftCost) internal returns (uint256 _ethFee) {
        // calculate PartyDAO fee & record total spent
        _ethFee = _getEthFee(_nftCost);
        totalSpent = _nftCost + _ethFee;
        // transfer ETH fee to PartyDAO
        _transferETHOrWETH(partyDAOMultisig, _ethFee);
        // deploy fractionalized NFT vault
        // and mint fractional ERC-20 tokens
        _fractionalizeNFT(_nftCost);
    }

    /**
     * @notice Calculate ETH fee for PartyDAO
     * NOTE: Remove this fee causes a critical vulnerability
     * allowing anyone to exploit a Party via price manipulation.
     * See Security Review in README for more info.
     * @return _fee the portion of _amount represented by scaling to ETH_FEE_BASIS_POINTS
     */
    function _getEthFee(uint256 _amount) internal pure returns (uint256 _fee) {
        _fee = (_amount * ETH_FEE_BASIS_POINTS) / 10000;
    }

    /**
     * @notice Calculate token amount for specified token recipient
     * @return _totalSupply the total token supply
     * @return _partyDAOAmount the amount of tokens for partyDAO fee,
     * which is equivalent to TOKEN_FEE_BASIS_POINTS of total supply
     * @return _splitRecipientAmount the amount of tokens for the token recipient,
     * which is equivalent to splitBasisPoints of total supply
     */
    function _getTokenInflationAmounts(uint256 _amountSpent)
        internal
        view
        returns (uint256 _totalSupply, uint256 _partyDAOAmount, uint256 _splitRecipientAmount)
    {
        // the token supply will be inflated to provide a portion of the
        // total supply for PartyDAO, and a portion for the splitRecipient
        uint256 inflationBasisPoints = TOKEN_FEE_BASIS_POINTS + splitBasisPoints;
        _totalSupply = valueToTokens((_amountSpent * 10000) / (10000 - inflationBasisPoints));
        // PartyDAO receives TOKEN_FEE_BASIS_POINTS of the total supply
        _partyDAOAmount = (_totalSupply * TOKEN_FEE_BASIS_POINTS) / 10000;
        // splitRecipient receives splitBasisPoints of the total supply
        _splitRecipientAmount = (_totalSupply * splitBasisPoints) / 10000;
    }

    /**
    * @notice Query the NFT contract to get the token owner
    * @dev nftContract must implement the ERC-721 token standard exactly:
    * function ownerOf(uint256 _tokenId) external view returns (address);
    * See https://eips.ethereum.org/EIPS/eip-721
    * @dev Returns address(0) if NFT token or NFT contract
    * no longer exists (token burned or contract self-destructed)
    * @return _owner the owner of the NFT
    */
    function _getOwner() internal view returns (address _owner) {
        (bool _success, bytes memory _returnData) =
            address(nftContract).staticcall(
                abi.encodeWithSignature(
                    "ownerOf(uint256)",
                    tokenId
                )
        );
        if (_success && _returnData.length > 0) {
            _owner = abi.decode(_returnData, (address));
        }
    }

    /**
     * @notice Upon winning the token, transfer the NFT
     * to fractional.art vault & mint fractional ERC-20 tokens
     */
    function _fractionalizeNFT(uint256 _amountSpent) internal {
        // approve fractionalized NFT Factory to withdraw NFT
        nftContract.approve(address(tokenVaultFactory), tokenId);
        // Party "votes" for a reserve price on Fractional
        // equal to 2x the price of the token
        uint256 _listPrice = RESALE_MULTIPLIER * _amountSpent;
        // users receive tokens at a rate of 1:TOKEN_SCALE for each ETH they contributed that was ultimately spent
        // partyDAO receives a percentage of the total token supply equivalent to TOKEN_FEE_BASIS_POINTS
        // splitRecipient receives a percentage of the total token supply equivalent to splitBasisPoints
        (uint256 _tokenSupply, uint256 _partyDAOAmount, uint256 _splitRecipientAmount) = _getTokenInflationAmounts(totalSpent);
        // deploy fractionalized NFT vault
        uint256 vaultNumber =
            tokenVaultFactory.mint(
                name,
                symbol,
                address(nftContract),
                tokenId,
                _tokenSupply,
                _listPrice,
                0
            );
        // store token vault address to storage
        tokenVault = ITokenVault(tokenVaultFactory.vaults(vaultNumber));
        // transfer curator to null address (burn the curator role)
        tokenVault.updateCurator(address(0));
        // transfer tokens to PartyDAO multisig
        _transferTokens(partyDAOMultisig, _partyDAOAmount);
        // transfer tokens to token recipient
        if (splitRecipient != address(0)) {
            _transferTokens(splitRecipient, _splitRecipientAmount);
        }
    }

    // ============ Internal: Claim ============

    /**
     * @notice Calculate the amount of a single Contribution
     * that was used towards buying the token
     * @param _contribution the Contribution struct
     * @return the amount of funds from this contribution
     * that were used towards buying the token
     */
    function _ethUsed(uint256 _totalSpent, Contribution memory _contribution)
        internal
        pure
        returns (uint256)
    {
        if (
            _contribution.previousTotalContributedToParty +
            _contribution.amount <=
            _totalSpent
        ) {
            // contribution was fully used
            return _contribution.amount;
        } else if (
            _contribution.previousTotalContributedToParty < _totalSpent
        ) {
            // contribution was partially used
            return _totalSpent - _contribution.previousTotalContributedToParty;
        }
        // contribution was not used
        return 0;
    }

    // ============ Internal: TransferTokens ============

    /**
    * @notice Transfer tokens to a recipient
    * @param _to recipient of tokens
    * @param _value amount of tokens
    */
    function _transferTokens(address _to, uint256 _value) internal {
        // skip if attempting to send 0 tokens
        if (_value == 0) {
            return;
        }
        // guard against rounding errors;
        // if token amount to send is greater than contract balance,
        // send full contract balance
        uint256 _partyBalance = tokenVault.balanceOf(address(this));
        if (_value > _partyBalance) {
            _value = _partyBalance;
        }
        tokenVault.transfer(_to, _value);
    }

    // ============ Internal: TransferEthOrWeth ============

    /**
     * @notice Attempt to transfer ETH to a recipient;
     * if transferring ETH fails, transfer WETH insteads
     * @param _to recipient of ETH or WETH
     * @param _value amount of ETH or WETH
     */
    function _transferETHOrWETH(address _to, uint256 _value) internal {
        // skip if attempting to send 0 ETH
        if (_value == 0) {
            return;
        }
        // guard against rounding errors;
        // if ETH amount to send is greater than contract balance,
        // send full contract balance
        if (_value > address(this).balance) {
            _value = address(this).balance;
        }
        // Try to transfer ETH to the given recipient.
        if (!_attemptETHTransfer(_to, _value)) {
            // If the transfer fails, wrap and send as WETH
            weth.deposit{value: _value}();
            weth.transfer(_to, _value);
            // At this point, the recipient can unwrap WETH.
        }
    }

    /**
     * @notice Attempt to transfer ETH to a recipient
     * @dev Sending ETH is not guaranteed to succeed
     * this method will return false if it fails.
     * We will limit the gas used in transfers, and handle failure cases.
     * @param _to recipient of ETH
     * @param _value amount of ETH
     */
    function _attemptETHTransfer(address _to, uint256 _value)
        internal
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = _to.call{value: _value, gas: 30000}("");
        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
 * @title IAllowList
 * @author Anna Carroll
 */
interface IAllowList {
    function allowed(address _addr) external view returns (bool _bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IERC721VaultFactory {
    /// @notice the mapping of vault number to vault address
    function vaults(uint256) external returns (address);

    /// @notice the function to mint a new vault
    /// @param _name the desired name of the vault
    /// @param _symbol the desired sumbol of the vault
    /// @param _token the ERC721 token address fo the NFT
    /// @param _id the uint256 ID of the token
    /// @param _listPrice the initial price of the NFT
    /// @return the ID of the vault
    function mint(string memory _name, string memory _symbol, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee) external returns(uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface ITokenVault {
    /// @notice allow curator to update the curator address
    /// @param _curator the new curator
    function updateCurator(address _curator) external;

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}