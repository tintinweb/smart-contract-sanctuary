pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import "../../interfaces/ISideStaking.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC20Template.sol";
import "../../interfaces/IERC721Template.sol";
import "../../interfaces/IPool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**@title SideStaking
 *
 * @dev SideStaking is a contract that monitors stakings in pools, 
        adding or removing dt when only baseToken liquidity is added or removed
 *      Called by the pool contract
 *      Every ss newDatatokenCreated function has a ssParams array, 
        which for this contract has the following structure: 
     *                     [0]  = rate (wei)
     *                     [1]  = baseToken decimals
     *                     [2]  = vesting amount (wei)
     *                     [3]  = vested blocks
     *                     [4]  = initial liquidity in baseToken for pool creation
 *
 */
contract SideStaking is ReentrancyGuard, ISideStaking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public router;

    // emitted when a new vesting is created
    event VestingCreated(
        address indexed datatokenAddress,
        address indexed publisherAddress,
        uint256 vestingEndBlock,
        uint256 totalVestingAmount
    );
    // emited each time when tokens are vested to the publisher
    event Vesting(
        address indexed datatokenAddress,
        address indexed publisherAddress,
        address indexed caller,
        uint256 amountVested
    );

    struct Record {
        bool bound; //datatoken bounded
        address baseTokenAddress;
        address poolAddress;
        bool poolFinalized; // did we finalized the pool ? We have to do it after burn-in
        uint256 datatokenBalance; //current dt balance
        uint256 datatokenCap; //dt cap
        uint256 baseTokenBalance; //current baseToken balance
        uint256 lastPrice; //used for creating the pool
        uint256 rate; // rate to exchange DT<->baseToken
        address publisherAddress;
        uint256 blockDeployed; //when this record was created
        uint256 vestingEndBlock; //see below
        uint256 vestingAmount; // total amount to be vested to publisher until vestingEndBlock
        uint256 vestingLastBlock; //last block in which a vesting has been granted
        uint256 vestingAmountSoFar; //how much was vested so far
    }

    mapping(address => Record) private _datatokens;
    uint256 private constant BASE = 1e18;

    modifier onlyRouter() {
        require(msg.sender == router, "ONLY ROUTER");
        _;
    }

    modifier onlyOwner(address datatoken) {
        require(
            datatoken != address(0),
            'Invalid token contract address'
        );
        // allow only ERC20 Deployers or NFT Owner
        IERC20Template dt = IERC20Template(datatoken);
        require(
            dt.isERC20Deployer(msg.sender) || 
            IERC721Template(dt.getERC721Address()).ownerOf(1) == msg.sender
            ,
            "Invalid owner"
        );
        _;
    }
    /**
     * @dev constructor
     *      Called on contract deployment.
     */
    constructor(address _router) {
        require(_router != address(0), "Invalid _router address");
        router = _router;
    }

    /**
     * @dev getId
     *      Return template id in case we need different ABIs.
     *      If you construct your own template, please make sure to change the hardcoded value
     */
    function getId() public pure returns (uint8) {
        return 1;
    }

    /**
     * @dev newDatatokenCreated
     *      Called when new Datatoken is deployed by the DatatokenFactory
     * @param datatokenAddress - datatokenAddress
     * @param baseTokenAddress -
     * @param poolAddress - poolAddress
     * @param publisherAddress - publisherAddress
     * @param ssParams  - ss Params, see below
     */

    function newDatatokenCreated(
        address datatokenAddress,
        address baseTokenAddress,
        address poolAddress,
        address publisherAddress,
        uint256[] memory ssParams
    ) external onlyRouter nonReentrant returns (bool) {
        //check if we are the controller of the pool
        require(poolAddress != address(0), "Invalid poolAddress");
        IPool bpool = IPool(poolAddress);
        require(
            bpool.getController() == address(this),
            "We are not the pool controller"
        );
        //check if the tokens are bound
        require(
            bpool.getDatatokenAddress() == datatokenAddress,
            "Datatoken address missmatch"
        );
        require(
            bpool.getBaseTokenAddress() == baseTokenAddress,
            "baseToken address missmatch"
        );
        require(ssParams[0]>1e12 , "Invalid rate");
        // check if we are the minter of DT
        IERC20Template dt = IERC20Template(datatokenAddress);
        require(
            (dt.permissions(address(this))).minter,
            "baseToken address mismatch"
        );
        // get cap and mint it..
        dt.mint(address(this), dt.cap());

        require(dt.balanceOf(address(this)) >= dt.totalSupply(), "Mint failed");

        //force vesting to 0, see https://github.com/oceanprotocol/contracts/issues/603
        ssParams[2] = 0;
        ssParams[3] = 0;
        require(dt.totalSupply().div(10) >= ssParams[2], "Max vesting 10%");
        //we are rich :)let's setup the records and we are good to go
        _datatokens[datatokenAddress] = Record({
            bound: true,
            baseTokenAddress: baseTokenAddress,
            poolAddress: poolAddress,
            poolFinalized: false,
            datatokenBalance: dt.totalSupply(),
            datatokenCap: dt.cap(),
            baseTokenBalance: ssParams[4],
            lastPrice: 0,
            rate: ssParams[0],
            publisherAddress: publisherAddress,
            blockDeployed: block.number,
            vestingEndBlock: block.number + ssParams[3],
            vestingAmount: ssParams[2],
            vestingLastBlock: block.number,
            vestingAmountSoFar: 0
        });
        emit VestingCreated(
            datatokenAddress,
            publisherAddress,
            _datatokens[datatokenAddress].vestingEndBlock,
            _datatokens[datatokenAddress].vestingAmount
        );

        _notifyFinalize(datatokenAddress, ssParams[1]);

        return (true);
    }

    //public getters
    /**
     *  Returns  (total vesting amount + token released from the contract when adding liquidity)
     * @param datatokenAddress - datatokenAddress

     */

    function getDatatokenCirculatingSupply(address datatokenAddress)
        external
        view
        returns (uint256)
    {
        if (!_datatokens[datatokenAddress].bound) return (0);
        return (_datatokens[datatokenAddress].datatokenCap -
            _datatokens[datatokenAddress].datatokenBalance);
    }

    /**
     *  Returns actual dts in circulation (vested token withdrawn from the contract +
         token released from the contract when adding liquidity)
     * @param datatokenAddress - datatokenAddress

     */

    function getDatatokenCurrentCirculatingSupply(address datatokenAddress)
        external
        view
        returns (uint256)
    {
        if (!_datatokens[datatokenAddress].bound) return (0);
        return (_datatokens[datatokenAddress].datatokenCap -
            _datatokens[datatokenAddress].datatokenBalance -
            _datatokens[datatokenAddress].vestingAmountSoFar);
    }

    /**
     *  Returns publisher address
     * @param datatokenAddress - datatokenAddress

     */

    function getPublisherAddress(address datatokenAddress)
        external
        view
        returns (address)
    {
        if (!_datatokens[datatokenAddress].bound) return (address(0));
        return (_datatokens[datatokenAddress].publisherAddress);
    }

    /**
     *  Returns baseToken address
     * @param datatokenAddress - datatokenAddress

     */

    function getBaseTokenAddress(address datatokenAddress)
        external
        view
        returns (address)
    {
        if (!_datatokens[datatokenAddress].bound) return (address(0));
        return (_datatokens[datatokenAddress].baseTokenAddress);
    }

    /**
     *  Returns pool address
     * @param datatokenAddress - datatokenAddress

     */

    function getPoolAddress(address datatokenAddress)
        external
        view
        returns (address)
    {
        if (!_datatokens[datatokenAddress].bound) return (address(0));
        return (_datatokens[datatokenAddress].poolAddress);
    }

    /**
     *  Returns baseToken balance in the contract
     * @param datatokenAddress - datatokenAddress

     */
    function getBaseTokenBalance(address datatokenAddress)
        external
        view
        returns (uint256)
    {
        if (!_datatokens[datatokenAddress].bound) return (0);
        return (_datatokens[datatokenAddress].baseTokenBalance);
    }

    /**
     *  Returns datatoken balance in the contract
     * @param datatokenAddress - datatokenAddress

     */

    function getDatatokenBalance(address datatokenAddress)
        external
        view
        returns (uint256)
    {
        if (!_datatokens[datatokenAddress].bound) return (0);
        return (_datatokens[datatokenAddress].datatokenBalance);
    }

    /**
     *  Returns last vesting block
     * @param datatokenAddress - datatokenAddress

     */

    function getvestingEndBlock(address datatokenAddress)
        external
        view
        returns (uint256)
    {
        if (!_datatokens[datatokenAddress].bound) return (0);
        return (_datatokens[datatokenAddress].vestingEndBlock);
    }

    /**
     *  Returns total vesting amount
     * @param datatokenAddress - datatokenAddress

     */

    function getvestingAmount(address datatokenAddress)
        public
        view
        returns (uint256)
    {
        if (!_datatokens[datatokenAddress].bound) return (0);
        return (_datatokens[datatokenAddress].vestingAmount);
    }

    /**
     *  Returns last block when some vesting tokens were collected
     * @param datatokenAddress - datatokenAddress

     */

    function getvestingLastBlock(address datatokenAddress)
        external
        view
        returns (uint256)
    {
        if (!_datatokens[datatokenAddress].bound) return (0);
        return (_datatokens[datatokenAddress].vestingLastBlock);
    }

    /**
     *  Returns amount of vested tokens that have been withdrawn from the contract so far
     * @param datatokenAddress - datatokenAddress

     */

    function getvestingAmountSoFar(address datatokenAddress)
        public
        view
        returns (uint256)
    {
        if (!_datatokens[datatokenAddress].bound) return (0);
        return (_datatokens[datatokenAddress].vestingAmountSoFar);
    }

    //called by pool to confirm that we can stake a token (add pool liquidty). If true, pool will call Stake function
    function canStake(address datatokenAddress, uint256 amount)
        public
        view
        returns (bool)
    {
        require(
            msg.sender == _datatokens[datatokenAddress].poolAddress,
            "ERR: Only pool can call this"
        );
        if (!_datatokens[datatokenAddress].bound) return (false);

        //check balances. Make sure that we have enough to vest
        if (
            _datatokens[datatokenAddress].datatokenBalance >=
            (amount +
                (_datatokens[datatokenAddress].vestingAmount -
                    _datatokens[datatokenAddress].vestingAmountSoFar))
        ) return (true);
        return (false);
    }

    //called by pool so 1ss will stake a token (add pool liquidty).
    // Function only needs to approve the amount to be spent by the pool, pool will do the rest
    function Stake(address datatokenAddress, uint256 amount)
        external
        nonReentrant
    {
        if (!_datatokens[datatokenAddress].bound) return;
        require(
            msg.sender == _datatokens[datatokenAddress].poolAddress,
            "ERR: Only pool can call this"
        );
        bool ok = canStake(datatokenAddress, amount);
        if (!ok) return;
        IERC20 dt = IERC20(datatokenAddress);
        dt.safeIncreaseAllowance(
            _datatokens[datatokenAddress].poolAddress,
            amount
        );
        _datatokens[datatokenAddress].datatokenBalance -= amount;
    }

    //called by pool to confirm that we can stake a token (add pool liquidty). If true, pool will call Unstake function
    function canUnStake(address datatokenAddress, uint256 lptIn)
        public
        view
        returns (bool)
    {
        //TO DO
        if (!_datatokens[datatokenAddress].bound) return (false);
        require(
            msg.sender == _datatokens[datatokenAddress].poolAddress,
            "ERR: Only pool can call this"
        );

        // we check LPT balance TODO: review this part
        if (IERC20(msg.sender).balanceOf(address(this)) >= lptIn) {
            return true;
        }
        return false;
    }

    //called by pool so 1ss will unstake a token (remove pool liquidty).
    // In our case the balancer pool will handle all, this is just a notifier so 1ss can handle internal kitchen
    function UnStake(
        address datatokenAddress,
        uint256 dtAmountIn,
        uint256 poolAmountOut
    ) external nonReentrant {
        if (!_datatokens[datatokenAddress].bound) return;
        require(
            msg.sender == _datatokens[datatokenAddress].poolAddress,
            "ERR: Only pool can call this"
        );
        bool ok = canUnStake(datatokenAddress, poolAmountOut);
        if (!ok) return;
        _datatokens[datatokenAddress].datatokenBalance += dtAmountIn;
    }

    //called by the pool (or by us) when we should finalize the pool
    function _notifyFinalize(address datatokenAddress, uint256 decimals)
        internal
    {
        if (!_datatokens[datatokenAddress].bound) return;
        if (_datatokens[datatokenAddress].poolFinalized) return;
        _datatokens[datatokenAddress].poolFinalized = true;
        uint256 baseTokenWeight = 5 * BASE; //pool weight: 50-50
        uint256 datatokenWeight = 5 * BASE; //pool weight: 50-50
        uint256 baseTokenAmount = _datatokens[datatokenAddress]
            .baseTokenBalance;
        //given the price, compute datatokenAmount

        uint256 datatokenAmount = (10**(18 - decimals))*_datatokens[datatokenAddress].rate *
            baseTokenAmount *
            datatokenWeight /
            baseTokenWeight /
            BASE;

        //substract
        _datatokens[datatokenAddress].baseTokenBalance -= baseTokenAmount;
        _datatokens[datatokenAddress].datatokenBalance -= datatokenAmount;
        //approve the tokens and amounts
        IERC20 dt = IERC20(datatokenAddress);
        dt.safeIncreaseAllowance(
            _datatokens[datatokenAddress].poolAddress,
            datatokenAmount
        );
        IERC20 dtBase = IERC20(_datatokens[datatokenAddress].baseTokenAddress);
        dtBase.safeIncreaseAllowance(
            _datatokens[datatokenAddress].poolAddress,
            baseTokenAmount
        );
        
        
        // call the pool, bind the tokens, set the price, finalize pool
        IPool pool = IPool(_datatokens[datatokenAddress].poolAddress);
        pool.setup(
            datatokenAddress,
            datatokenAmount,
            datatokenWeight,
            _datatokens[datatokenAddress].baseTokenAddress,
            baseTokenAmount,
            baseTokenWeight
        );
        // send 50% of the pool shares back to the publisher
        IERC20 lPTokens = IERC20(_datatokens[datatokenAddress].poolAddress);
        uint256 lpBalance = lPTokens.balanceOf(address(this));
        //  uint256 balanceToTransfer = lpBalance.div(2);
        lPTokens.safeTransfer(
            _datatokens[datatokenAddress].publisherAddress,
            lpBalance.div(2)
        );
    }

    /**
     *  Get available vesting now
     * param datatokenAddress - datatokenAddress

     */
    function getAvailableVesting(address)
        public
        pure
        returns (uint256)
    {
        // see https://github.com/oceanprotocol/contracts/issues/603
        return 0;
    }

    /**
     *  Send available vested tokens to the publisher address, can be called by anyone
     * @param datatokenAddress - datatokenAddress

     */
    // called by vester to get datatokens
    function getVesting(address datatokenAddress) external nonReentrant {
        require(_datatokens[datatokenAddress].bound, "ERR:Invalid datatoken");
        uint256 amount = getAvailableVesting(datatokenAddress);
        if (
            amount > 0 &&
            _datatokens[datatokenAddress].datatokenBalance >= amount
        ) {
            IERC20Template dt = IERC20Template(datatokenAddress);
            _datatokens[datatokenAddress].vestingLastBlock = block.number;
            _datatokens[datatokenAddress].datatokenBalance -= amount;
            _datatokens[datatokenAddress].vestingAmountSoFar += amount;
            address collector = dt.getPaymentCollector();
            emit Vesting(
                datatokenAddress,
                collector,
                msg.sender,
                amount
            );
            dt.transfer(
                collector,
                amount
            );
            
        }
    }

    /**
     *  Change pool fee
     * @param datatokenAddress - datatokenAddress
     * @param poolAddress - poolAddress
     * @param swapFee - new fee

     */
    // called by ERC20 Deployer of datatoken
    function setPoolSwapFee(
        address datatokenAddress,
        address poolAddress,
        uint256 swapFee
    ) external onlyOwner(datatokenAddress) nonReentrant {
        require(_datatokens[datatokenAddress].bound, "Invalid datatoken");
        require(poolAddress != address(0), "Invalid poolAddress");
        IPool bpool = IPool(poolAddress);
        require(
            bpool.getController() == address(this),
            "We are not the pool controller"
        );
        //check if the tokens are bound
        require(
            bpool.getDatatokenAddress() == datatokenAddress,
            "Datatoken address missmatch"
        );
        bpool.setSwapFee(swapFee);
    }
}

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface ISideStaking {


    function newDatatokenCreated(
        address datatokenAddress,
        address baseTokenAddress,
        address poolAddress,
        address publisherAddress,
        uint256[] calldata ssParams
    ) external returns (bool);

    function getDatatokenCirculatingSupply(address datatokenAddress)
        external
        view
        returns (uint256);

    function getPublisherAddress(address datatokenAddress)
        external
        view
        returns (address);

    function getBaseTokenAddress(address datatokenAddress)
        external
        view
        returns (address);

    function getPoolAddress(address datatokenAddress)
        external
        view
        returns (address);

    function getBaseTokenBalance(address datatokenAddress)
        external
        view
        returns (uint256);

    function getDatatokenBalance(address datatokenAddress)
        external
        view
        returns (uint256);

    function getvestingEndBlock(address datatokenAddress)
        external
        view
        returns (uint256);

    function getvestingAmount(address datatokenAddress)
        external
        view
        returns (uint256);

    function getvestingLastBlock(address datatokenAddress)
        external
        view
        returns (uint256);

    function getvestingAmountSoFar(address datatokenAddress)
        external
        view
        returns (uint256);



    function canStake(
        address datatokenAddress,
        uint256 amount
    ) external view returns (bool);

    function Stake(
        address datatokenAddress,
        uint256 amount
    ) external;

    function canUnStake(
        address datatokenAddress,
        uint256 amount
    ) external view returns (bool);

    function UnStake(
        address datatokenAddress,
        uint256 amount,
        uint256 poolAmountIn
    ) external;

    function getId() pure external returns (uint8);

  
}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
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

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface IERC20Template {
    struct RolesERC20 {
        bool minter;
        bool feeManager;
    }
    struct providerFee{
        address providerFeeAddress;
        address providerFeeToken; // address of the token marketplace wants to add fee on top
        uint256 providerFeeAmount; // amount to be transfered to marketFeeCollector
        uint8 v; // v of provider signed message
        bytes32 r; // r of provider signed message
        bytes32 s; // s of provider signed message
        uint256 validUntil; //validity expresses in unix timestamp
        bytes providerData; //data encoded by provider
    }
    struct consumeMarketFee{
        address consumeMarketFeeAddress;
        address consumeMarketFeeToken; // address of the token marketplace wants to add fee on top
        uint256 consumeMarketFeeAmount; // amount to be transfered to marketFeeCollector
    }
    function initialize(
        string[] calldata strings_,
        address[] calldata addresses_,
        address[] calldata factoryAddresses_,
        uint256[] calldata uints_,
        bytes[] calldata bytes_
    ) external returns (bool);
    
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address account, uint256 value) external;
    
    function isMinter(address account) external view returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permissions(address user)
        external
        view
        returns (RolesERC20 memory);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function cleanFrom721() external;

    function deployPool(
        uint256[] memory ssParams,
        uint256[] memory swapFees,
        address[] memory addresses 
    ) external returns (address);

    function createFixedRate(
        address fixedPriceAddress,
        address[] memory addresses,
        uint[] memory uints
    ) external returns (bytes32);
    function createDispenser(
        address _dispenser,
        uint256 maxTokens,
        uint256 maxBalance,
        bool withMint,
        address allowedSwapper) external;
        
    function getPublishingMarketFee() external view returns (address , address, uint256);
    function setPublishingMarketFee(
        address _publishMarketFeeAddress, address _publishMarketFeeToken, uint256 _publishMarketFeeAmount
    ) external;

     function startOrder(
        address consumer,
        uint256 serviceIndex,
        providerFee calldata _providerFee,
        consumeMarketFee calldata _consumeMarketFee
     ) external;

     function reuseOrder(
        bytes32 orderTxId,
        providerFee calldata _providerFee
    ) external;
  
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function getERC721Address() external view returns (address);
    function isERC20Deployer(address user) external view returns(bool);
    function getPools() external view returns(address[] memory);
    struct fixedRate{
        address contractAddress;
        bytes32 id;
    }
    function getFixedRates() external view returns(fixedRate[] memory);
    function getDispensers() external view returns(address[] memory);
    function getId() pure external returns (uint8);
    function getPaymentCollector() external view returns (address);
}

pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Template {
    
    enum RolesType {
        Manager,
        DeployERC20,
        UpdateMetadata,
        Store
    }
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event MetadataCreated(
        address indexed createdBy,
        uint8 state,
        string decryptorUrl,
        bytes flags,
        bytes data,
        string metaDataDecryptorAddress,
        uint256 timestamp,
        uint256 blockNumber
    );
    event MetadataUpdated(
        address indexed updatedBy,
        uint8 state,
        string decryptorUrl,
        bytes flags,
        bytes data,
        string metaDataDecryptorAddress,
        uint256 timestamp,
        uint256 blockNumber
    );
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isERC20Deployer(address acount) external view returns (bool);
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, 
     * it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, 
     * it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, 
     * it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external;
    function transferFrom(address from, address to) external;

    function initialize(
        address admin,
        string calldata name,
        string calldata symbol,
        address erc20Factory,
        address additionalERC20Deployer,
        address additionalMetaDataUpdater,
        string calldata tokenURI,
        bool transferable
    ) external returns (bool);

     struct Roles {
        bool manager;
        bool deployERC20;
        bool updateMetadata;
        bool store;
    }

    struct metaDataProof {
        address validatorAddress;
        uint8 v; // v of validator signed message
        bytes32 r; // r of validator signed message
        bytes32 s; // s of validator signed message
    }
    function getPermissions(address user) external view returns (Roles memory);

    function setDataERC20(bytes32 _key, bytes calldata _value) external;
    function setMetaData(uint8 _metaDataState, string calldata _metaDataDecryptorUrl
        , string calldata _metaDataDecryptorAddress, bytes calldata flags, 
        bytes calldata data,bytes32 _metaDataHash, metaDataProof[] memory _metadataProofs) external;
    function getMetaData() external view returns (string memory, string memory, uint8, bool);

    function createERC20(
        uint256 _templateIndex,
        string[] calldata strings,
        address[] calldata addresses,
        uint256[] calldata uints,
        bytes[] calldata bytess
    ) external returns (address);


    function removeFromCreateERC20List(address _allowedAddress) external;
    function addToCreateERC20List(address _allowedAddress) external;
    function addToMetadataList(address _allowedAddress) external;
    function removeFromMetadataList(address _allowedAddress) external;
    function getId() pure external returns (uint8);
}

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.12;
// Copyright Balancer, BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface IPool {
    function getDatatokenAddress() external view returns (address);

    function getBaseTokenAddress() external view returns (address);

    function getController() external view returns (address);

    function setup(
        address datatokenAddress,
        uint256 datatokenAmount,
        uint256 datatokennWeight,
        address baseTokenAddress,
        uint256 baseTokenAmount,
        uint256 baseTokenWeight
    ) external;

    function swapExactAmountIn(
        address[3] calldata tokenInOutMarket, //[tokenIn,tokenOut,marketFeeAddress]
        uint256[4] calldata amountsInOutMaxFee //[tokenAmountIn,minAmountOut,maxPrice,_swapMarketFee]
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address[3] calldata tokenInOutMarket, // [tokenIn,tokenOut,marketFeeAddress]
        uint256[4] calldata amountsInOutMaxFee // [maxAmountIn,tokenAmountOut,maxPrice,_swapMarketFee]
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function getAmountInExactOut(
        address tokenIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 _consumeMarketSwapFee
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function getAmountOutExactIn(
        address tokenIn,
        address tokenOut,
        uint256 tokenAmountIn,
        uint256 _consumeMarketSwapFee
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function setSwapFee(uint256 swapFee) external;
    function getId() pure external returns (uint8);

    function exitswapPoolAmountIn(
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);
    
    function joinswapExternAmountIn(
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../interfaces/IERC20.sol";
import "./ERC721/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

pragma solidity 0.8.12;
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }


}


// File @openzeppelin/contracts/utils/[email protected]