// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


import {YearnVaultAdapterWithIndirection} from "./adapters/YearnVaultAdapterWithIndirection.sol";
import {VaultWithIndirection} from "./libraries/carbon/VaultWithIndirection.sol";
import {ITransmuter} from "./interfaces/ITransmuter.sol";
interface IERC20Burnable is IERC20Upgradeable {
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}

// import "hardhat/console.sol";

//    ___    __        __                _               ___                              __         _ 
//   / _ |  / / ____  / /  ___   __ _   (_) __ __       / _ \  ____ ___   ___ ___   ___  / /_  ___  (_)
//  / __ | / / / __/ / _ \/ -_) /  ' \ / /  \ \ /      / ___/ / __// -_) (_-</ -_) / _ \/ __/ (_-< _
// /_/ |_|/_/  \__/ /_//_/\__/ /_/_/_//_/  /_\_\      /_/    /_/   \__/ /___/\__/ /_//_/\__/ /___/(_)
//
// .___________..______           ___      .__   __.      _______..___  ___.  __    __  .___________. _______ .______
// |           ||   _  \         /   \     |  \ |  |     /       ||   \/   | |  |  |  | |           ||   ____||   _  \
// `---|  |----`|  |_)  |       /  ^  \    |   \|  |    |   (----`|  \  /  | |  |  |  | `---|  |----`|  |__   |  |_)  |
//     |  |     |      /       /  /_\  \   |  . `  |     \   \    |  |\/|  | |  |  |  |     |  |     |   __|  |      /
//     |  |     |  |\  \----. /  _____  \  |  |\   | .----)   |   |  |  |  | |  `--'  |     |  |     |  |____ |  |\  \----.
//     |__|     | _| `._____|/__/     \__\ |__| \__| |_______/    |__|  |__|  \______/      |__|     |_______|| _| `._____|
/**
 * @dev Implementation of the {IERC20Burnable} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20Burnable-approve}.
 */
contract TransmuterB is ContextUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Burnable;
    using AddressUpgradeable for address;
    using VaultWithIndirection for VaultWithIndirection.Data;
    using VaultWithIndirection for VaultWithIndirection.List;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public TRANSMUTATION_PERIOD;

    address public alToken;
    address public token;

    mapping(address => uint256) public depositedAlTokens;
    mapping(address => uint256) public tokensInBucket;
    mapping(address => uint256) public realisedTokens;
    mapping(address => uint256) public lastDividendPoints;

    mapping(address => bool) public userIsKnown;
    mapping(uint256 => address) public userList;
    uint256 public nextUser;

    uint256 public totalSupplyAltokens;
    uint256 public buffer;
    uint256 public lastDepositBlock;

    ///@dev values needed to calculate the distribution of base asset in proportion for alTokens staked
    uint256 public  pointMultiplier;

    uint256 public totalDividendPoints;
    uint256 public unclaimedDividends;

    /// @dev alchemist addresses whitelisted
    mapping (address => bool) public whiteList;

    /// @dev The threshold above which excess funds will be deployed to yield farming activities
    uint256 public plantableThreshold; // 5mm

    /// @dev The % margin to trigger planting or recalling of funds
    uint256 public plantableMargin ;

    /// @dev The address of the account which currently has administrative capabilities over this contract.
    address public governance;

    
  /// @dev A flag indicating if the contract has been initialized yet.
  bool public initialized;

    /// @dev The address of the pending governance.
    address public pendingGovernance;

    /// @dev The address of the account which can perform emergency activities
    address public sentinel;

    /// @dev A flag indicating if deposits and flushes should be halted and if all parties should be able to recall
    /// from the active vault.
    bool public pause;

    /// @dev The address of the contract which will receive fees.
    address public rewards;

    /// @dev A list of all of the vaults. The last element of the list is the vault that is currently being used for
    /// deposits and withdraws. VaultWithIndirections before the last element are considered inactive and are expected to be cleared.
    VaultWithIndirection.List private _vaults;

    event GovernanceUpdated(
        address governance
    );

    event AlTokenAddressUpdated(
        address alToken
    );

    event TokenAddressUpdated(
        address Token
    );

    event PendingGovernanceUpdated(
        address pendingGovernance
    );

    event SentinelUpdated(
        address sentinel
    );

    event TransmuterPeriodUpdated(
        uint256 newTransmutationPeriod
    );

    event TokenClaimed(
        address claimant,
        address token,
        uint256 amountClaimed
    );

    event AlUsdStaked(
        address staker,
        uint256 amountStaked
    );

    event AlUsdUnstaked(
        address staker,
        uint256 amountUnstaked
    );

    event Transmutation(
        address transmutedTo,
        uint256 amountTransmuted
    );

    event ForcedTransmutation(
        address transmutedBy,
        address transmutedTo,
        uint256 amountTransmuted
    );

    event Distribution(
        address origin,
        uint256 amount
    );

    event WhitelistSet(
        address whitelisted,
        bool state
    );

    event PlantableThresholdUpdated(
        uint256 plantableThreshold
    );
    
    event PlantableMarginUpdated(
        uint256 plantableMargin
    );

    event ActiveVaultUpdated(
        YearnVaultAdapterWithIndirection indexed adapter
    );

    event PauseUpdated(
        bool status
    );

    event FundsRecalled(
        uint256 indexed vaultId,
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );

    event FundsHarvested(
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );

    event RewardsUpdated(
        address treasury
    );

    event MigrationComplete(
        address migrateTo,
        uint256 fundsMigrated
    );

    function setAlTokenAddress(address _alToken) public  onlyGov{
        alToken = _alToken;
        emit AlTokenAddressUpdated(alToken);
        
        
    }
    function setTokenAddress(address _token) public  onlyGov{
        token = _token;
        emit TokenAddressUpdated(token);
        
    }

 /// @dev Checks that the contract is in an initialized state.
  ///
  /// This is used over a modifier to reduce the size of the contract
  modifier expectInitialized() {
    require(initialized, "TransmuterB: not initialized.");
    _;
  }

    function initialize() public  initializer{
        require(!initialized,"already initialized");
        governance = msg.sender;
        TRANSMUTATION_PERIOD = 50;
        pointMultiplier = 10e18;
        plantableThreshold = 5000000000000000000000000;
        plantableMargin = 5;
        initialized = true;
      
    }

    ///@return displays the user's share of the pooled alTokens.
    function dividendsOwing(address account) public view returns (uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(lastDividendPoints[account]);
        return depositedAlTokens[account].mul(newDividendPoints).div(pointMultiplier);
    }

    ///@dev modifier to fill the bucket and keep bookkeeping correct incase of increase/decrease in shares
    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);
        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            tokensInBucket[account] = tokensInBucket[account].add(owing);
        }
        lastDividendPoints[account] = totalDividendPoints;
        _;
    }
    ///@dev modifier add users to userlist. Users are indexed in order to keep track of when a bond has been filled
    modifier checkIfNewUser() {
        if (!userIsKnown[msg.sender]) {
            userList[nextUser] = msg.sender;
            userIsKnown[msg.sender] = true;
            nextUser++;
        }
        _;
    }

    ///@dev run the phased distribution of the buffered funds
    modifier runPhasedDistribution() {
        uint256 _lastDepositBlock = lastDepositBlock;
        uint256 _currentBlock = block.number;
        uint256 _toDistribute = 0;
        uint256 _buffer = buffer;

        // check if there is something in bufffer
        if (_buffer > 0) {
            // NOTE: if last deposit was updated in the same block as the current call
            // then the below logic gates will fail

            //calculate diffrence in time
            uint256 deltaTime = _currentBlock.sub(_lastDepositBlock);

            // distribute all if bigger than timeframe
            if(deltaTime >= TRANSMUTATION_PERIOD) {
                _toDistribute = _buffer;
            } else {

                //needs to be bigger than 0 cuzz solidity no decimals
                if(_buffer.mul(deltaTime) > TRANSMUTATION_PERIOD)
                {
                    _toDistribute = _buffer.mul(deltaTime).div(TRANSMUTATION_PERIOD);
                }
            }

            // factually allocate if any needs distribution
            if(_toDistribute > 0){

                // remove from buffer
                buffer = _buffer.sub(_toDistribute);

                // increase the allocation
                increaseAllocations(_toDistribute);
            }
        }

        // current timeframe is now the last
        lastDepositBlock = _currentBlock;
        _;
    }

    /// @dev A modifier which checks if whitelisted for minting.
    modifier onlyWhitelisted() {
        require(whiteList[msg.sender], "Transmuter: !whitelisted");
        _;
    }

    /// @dev Checks that the current message sender or caller is the governance address.
    ///
    ///
    modifier onlyGov() {
        require(msg.sender == governance, "Transmuter: !governance");
        _;
    }

    ///@dev set the TRANSMUTATION_PERIOD variable
    ///
    /// sets the length (in blocks) of one full distribution phase
    function setTransmutationPeriod(uint256 newTransmutationPeriod) public expectInitialized onlyGov() {
        TRANSMUTATION_PERIOD = newTransmutationPeriod;
        emit TransmuterPeriodUpdated(TRANSMUTATION_PERIOD);
    }

    ///@dev claims the base token after it has been transmuted
    ///
    ///This function reverts if there is no realisedToken balance
    function claim() public {
        address sender = msg.sender;
        require(realisedTokens[sender] > 0);
        uint256 value = realisedTokens[sender];
        realisedTokens[sender] = 0;
        ensureSufficientFundsExistLocally(value);
        IERC20Burnable(token).safeTransfer(sender, value);
        emit TokenClaimed(sender, token, value);
    }

    ///@dev Withdraws staked alTokens from the transmuter
    ///
    /// This function reverts if you try to draw more tokens than you deposited
    ///
    ///@param amount the amount of alTokens to unstake
    function unstake(uint256 amount) public updateAccount(msg.sender) {
        // by calling this function before transmuting you forfeit your gained allocation
        address sender = msg.sender;
        require(depositedAlTokens[sender] >= amount,"Transmuter: unstake amount exceeds deposited amount");
        depositedAlTokens[sender] = depositedAlTokens[sender].sub(amount);
        totalSupplyAltokens = totalSupplyAltokens.sub(amount);
        IERC20Burnable(alToken).safeTransfer(sender, amount);
        emit AlUsdUnstaked(sender, amount);
    }
    ///@dev Deposits alTokens into the transmuter 
    ///
    ///@param amount the amount of alTokens to stake
    function stake(uint256 amount)
        public
        runPhasedDistribution()
        updateAccount(msg.sender)
        checkIfNewUser()
        expectInitialized
    {
        require(!pause, "emergency pause enabled");

        // requires approval of AlToken first
        address sender = msg.sender;
        //require tokens transferred in;
        IERC20Burnable(alToken).safeTransferFrom(sender, address(this), amount);
        totalSupplyAltokens = totalSupplyAltokens.add(amount);
        depositedAlTokens[sender] = depositedAlTokens[sender].add(amount);
        emit AlUsdStaked(sender, amount);
    }
    /// @dev Converts the staked alTokens to the base tokens in amount of the sum of pendingdivs and tokensInBucket
    ///
    /// once the alToken has been converted, it is burned, and the base token becomes realisedTokens which can be recieved using claim()    
    ///
    /// reverts if there are no pendingdivs or tokensInBucket
    function transmute() public expectInitialized runPhasedDistribution() updateAccount(msg.sender) {
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[sender];
        uint256 diff;

        require(pendingz > 0, "need to have pending in bucket");

        tokensInBucket[sender] = 0;

        // check bucket overflow
        if (pendingz > depositedAlTokens[sender]) {
            diff = pendingz.sub(depositedAlTokens[sender]);

            // remove overflow
            pendingz = depositedAlTokens[sender];
        }

        // decrease altokens
        depositedAlTokens[sender] = depositedAlTokens[sender].sub(pendingz);

        // BURN ALTOKENS
        IERC20Burnable(alToken).burn(pendingz);

        // adjust total
        totalSupplyAltokens = totalSupplyAltokens.sub(pendingz);

        // reallocate overflow
        increaseAllocations(diff);

        // add payout
        realisedTokens[sender] = realisedTokens[sender].add(pendingz);

        emit Transmutation(sender, pendingz);
    }

    /// @dev Executes transmute() on another account that has had more base tokens allocated to it than alTokens staked.
    ///
    /// The caller of this function will have the surlus base tokens credited to their tokensInBucket balance, rewarding them for performing this action
    ///
    /// This function reverts if the address to transmute is not over-filled.
    ///
    /// @param toTransmute address of the account you will force transmute.
    function forceTransmute(address toTransmute)
        public
        runPhasedDistribution()
        updateAccount(msg.sender)
        updateAccount(toTransmute)
        checkIfNewUser()
        expectInitialized
    {
        //load into memory
        address sender = msg.sender;
        uint256 pendingz = tokensInBucket[toTransmute];
        // check restrictions
        require(
            pendingz > depositedAlTokens[toTransmute],
            "Transmuter: !overflow"
        );

        // empty bucket
        tokensInBucket[toTransmute] = 0;

        // calculaate diffrence
        uint256 diff = pendingz.sub(depositedAlTokens[toTransmute]);

        // remove overflow
        pendingz = depositedAlTokens[toTransmute];

        // decrease altokens
        depositedAlTokens[toTransmute] = 0;

        // BURN ALTOKENS
        IERC20Burnable(alToken).burn(pendingz);
        // adjust total
        totalSupplyAltokens = totalSupplyAltokens.sub(pendingz);

        // reallocate overflow
        tokensInBucket[sender] = tokensInBucket[sender].add(diff);

        // add payout
        realisedTokens[toTransmute] = realisedTokens[toTransmute].add(pendingz);

        uint256 value = realisedTokens[toTransmute];

        ensureSufficientFundsExistLocally(value);

        // force payout of realised tokens of the toTransmute address
        realisedTokens[toTransmute] = 0;
        IERC20Burnable(token).safeTransfer(toTransmute, value);
        emit ForcedTransmutation(sender, toTransmute, value);
    }

    /// @dev Transmutes and unstakes all alTokens
    ///
    /// This function combines the transmute and unstake functions for ease of use
    function exit() public {
        transmute();
        uint256 toWithdraw = depositedAlTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Transmutes and claims all converted base tokens.
    ///
    /// This function combines the transmute and claim functions while leaving your remaining alTokens staked.
    function transmuteAndClaim() public {
        transmute();
        claim();
    }

    /// @dev Transmutes, claims base tokens, and withdraws alTokens.
    ///
    /// This function helps users to exit the transmuter contract completely after converting their alTokens to the base pair.
    function transmuteClaimAndWithdraw() public {
        transmute();
        claim();
        uint256 toWithdraw = depositedAlTokens[msg.sender];
        unstake(toWithdraw);
    }

    /// @dev Distributes the base token proportionally to all alToken stakers.
    ///
    /// This function is meant to be called by the Alchemist contract for when it is sending yield to the transmuter. 
    /// Anyone can call this and add funds, idk why they would do that though...
    ///
    /// @param origin the account that is sending the tokens to be distributed.
    /// @param amount the amount of base tokens to be distributed to the transmuter.
    function distribute(address origin, uint256 amount) public onlyWhitelisted() runPhasedDistribution() {
        require(!pause, "emergency pause enabled");
        IERC20Burnable(token).safeTransferFrom(origin, address(this), amount);
        buffer = buffer.add(amount);
        _plantOrRecallExcessFunds();
        emit Distribution(origin, amount);
    }

    /// @dev Allocates the incoming yield proportionally to all alToken stakers.
    ///
    /// @param amount the amount of base tokens to be distributed in the transmuter.
    function increaseAllocations(uint256 amount) internal {
        if(totalSupplyAltokens > 0 && amount > 0) {
            totalDividendPoints = totalDividendPoints.add(
                amount.mul(pointMultiplier).div(totalSupplyAltokens)
            );
            unclaimedDividends = unclaimedDividends.add(amount);
        } else {
            buffer = buffer.add(amount);
        }
    }

    /// @dev Gets the status of a user's staking position.
    ///
    /// The total amount allocated to a user is the sum of pendingdivs and inbucket.
    ///
    /// @param user the address of the user you wish to query.
    ///
    /// returns user status
    
    function userInfo(address user)
        public
        view
        returns (
            uint256 depositedAl,
            uint256 pendingdivs,
            uint256 inbucket,
            uint256 realised
        )
    {
        uint256 _depositedAl = depositedAlTokens[user];
        uint256 _toDistribute = buffer.mul(block.number.sub(lastDepositBlock)).div(TRANSMUTATION_PERIOD);
        if(block.number.sub(lastDepositBlock) > TRANSMUTATION_PERIOD){
            _toDistribute = buffer;
        }
        uint256 _pendingdivs = _toDistribute.mul(depositedAlTokens[user]).div(totalSupplyAltokens);
        uint256 _inbucket = tokensInBucket[user].add(dividendsOwing(user));
        uint256 _realised = realisedTokens[user];
        return (_depositedAl, _pendingdivs, _inbucket, _realised);
    }

    /// @dev Gets the status of multiple users in one call
    ///
    /// This function is used to query the contract to check for
    /// accounts that have overfilled positions in order to check 
    /// who can be force transmuted.
    ///
    /// @param from the first index of the userList
    /// @param to the last index of the userList
    ///
    /// returns the userList with their staking status in paginated form. 
    function getMultipleUserInfo(uint256 from, uint256 to)
        public
        view
        returns (address[] memory theUserList, uint256[] memory theUserData)
    {
        uint256 i = from;
        uint256 delta = to - from;
        address[] memory _theUserList = new address[](delta); //user
        uint256[] memory _theUserData = new uint256[](delta * 2); //deposited-bucket
        uint256 y = 0;
        uint256 _toDistribute = buffer.mul(block.number.sub(lastDepositBlock)).div(TRANSMUTATION_PERIOD);
        if(block.number.sub(lastDepositBlock) > TRANSMUTATION_PERIOD){
            _toDistribute = buffer;
        }
        for (uint256 x = 0; x < delta; x += 1) {
            _theUserList[x] = userList[i];
            _theUserData[y] = depositedAlTokens[userList[i]];
            _theUserData[y + 1] = dividendsOwing(userList[i]).add(tokensInBucket[userList[i]]).add(_toDistribute.mul(depositedAlTokens[userList[i]]).div(totalSupplyAltokens));
            y += 2;
            i += 1;
        }
        return (_theUserList, _theUserData);
    }

    /// @dev Gets info on the buffer
    ///
    /// This function is used to query the contract to get the
    /// latest state of the buffer
    ///
    /// @return _toDistribute the amount ready to be distributed
    /// @return _deltaBlocks the amount of time since the last phased distribution
    /// @return _buffer the amount in the buffer 
    function bufferInfo() public view returns (uint256 _toDistribute, uint256 _deltaBlocks, uint256 _buffer){
        _deltaBlocks = block.number.sub(lastDepositBlock);
        _buffer = buffer; 
        _toDistribute = _buffer.mul(_deltaBlocks).div(TRANSMUTATION_PERIOD);
    }

    /// @dev Sets the pending governance.
    ///
    /// This function reverts if the new pending governance is the zero address or the caller is not the current
    /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
    /// privileged contract functionality.
    ///
    /// @param _pendingGovernance the new pending governance.
    function setPendingGovernance(address _pendingGovernance) external onlyGov() {
        require(_pendingGovernance != ZERO_ADDRESS, "Transmuter: 0 gov");

        pendingGovernance = _pendingGovernance;

        emit PendingGovernanceUpdated(_pendingGovernance);
    }

    /// @dev Accepts the role as governance.
    ///
    /// This function reverts if the caller is not the new pending governance.
    function acceptGovernance() external  {
        require(msg.sender == pendingGovernance,"!pendingGovernance");
        address _pendingGovernance = pendingGovernance;
        governance = _pendingGovernance;

        emit GovernanceUpdated(_pendingGovernance);
    }

    /// @dev Sets the whitelist
    ///
    /// This function reverts if the caller is not governance
    ///
    /// @param _toWhitelist the account to mint tokens to.
    /// @param _state the whitelist state.
    function setWhitelist(address _toWhitelist, bool _state) external onlyGov() {
        whiteList[_toWhitelist] = _state;
        emit WhitelistSet(_toWhitelist, _state);
    }

    /// @dev Updates the active vault.
    ///
    /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
    /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
    ///
    /// @param _adapter the adapter for the new active vault.
    function setActiveVault(YearnVaultAdapterWithIndirection _adapter) external onlyGov() {
        require(_adapter != YearnVaultAdapterWithIndirection(ZERO_ADDRESS), "Transmuter: active vault address cannot be 0x0.");
        require(address(_adapter.token()) == token, "Transmuter.vault: token mismatch.");

        _vaults.push(VaultWithIndirection.Data({
            adapter: _adapter,
            totalDeposited: 0
        }));

        emit ActiveVaultUpdated(_adapter);
    }


    /// @dev Recalls funds from active vault if less than amt exist locally
    ///
    /// @param amt amount of funds that need to exist locally to fulfill pending request
    function ensureSufficientFundsExistLocally(uint256 amt) internal {
        uint256 currentBal = IERC20Burnable(token).balanceOf(address(this));
        if (currentBal < amt) {
            uint256 diff = amt - currentBal;
            // get enough funds from active vault to replenish local holdings & fulfill claim request
            _recallExcessFundsFromActiveVault(plantableThreshold.add(diff));
        }
    }

    /// @dev Recalls all planted funds from a target vault
    ///
    /// @param _vaultId the id of the vault from which to recall funds
    function recallAllFundsFromVault(uint256 _vaultId) external {
        require(pause && (msg.sender == governance || msg.sender == sentinel), "Transmuter: not paused, or not governance or sentinel");
        _recallAllFundsFromVault(_vaultId);
    }

    /// @dev Recalls all planted funds from a target vault
    ///
    /// @param _vaultId the id of the vault from which to recall funds
    function _recallAllFundsFromVault(uint256 _vaultId) internal {
        VaultWithIndirection.Data storage _vault = _vaults.get(_vaultId);
        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdrawAll(address(this));
        emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);
    }

    /// @dev Recalls planted funds from a target vault
    ///
    /// @param _vaultId the id of the vault from which to recall funds
    /// @param _amount the amount of funds to recall
    function recallFundsFromVault(uint256 _vaultId, uint256 _amount) external {
        require(pause && (msg.sender == governance || msg.sender == sentinel), "Transmuter: not paused, or not governance or sentinel");
        _recallFundsFromVault(_vaultId, _amount);
    }

    /// @dev Recalls planted funds from a target vault
    ///
    /// @param _vaultId the id of the vault from which to recall funds
    /// @param _amount the amount of funds to recall
    function _recallFundsFromVault(uint256 _vaultId, uint256 _amount) internal {
        VaultWithIndirection.Data storage _vault = _vaults.get(_vaultId);
        (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdraw(address(this), _amount);
        emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);
    }

    /// @dev Recalls planted funds from the active vault
    ///
    /// @param _amount the amount of funds to recall
    function _recallFundsFromActiveVault(uint256 _amount) internal {
        _recallFundsFromVault(_vaults.lastIndex(), _amount);
    }

    /// @dev Plants or recalls funds from the active vault
    ///
    /// This function plants excess funds in an external vault, or recalls them from the external vault
    /// Should only be called as part of distribute()
    function _plantOrRecallExcessFunds() internal {
        // check if the transmuter holds more funds than plantableThreshold
        uint256 bal = IERC20Burnable(token).balanceOf(address(this));
        uint256 marginVal = plantableThreshold.mul(plantableMargin).div(100);
        if (bal > plantableThreshold.add(marginVal)) {
            uint256 plantAmt = bal - plantableThreshold;
            // if total funds above threshold, send funds to vault
            VaultWithIndirection.Data storage _activeVault = _vaults.last();
            _activeVault.deposit(plantAmt);
        } else if (bal < plantableThreshold.sub(marginVal)) {
            // if total funds below threshold, recall funds from vault
            // first check that there are enough funds in vault
            uint256 harvestAmt = plantableThreshold - bal;
            _recallExcessFundsFromActiveVault(harvestAmt);
        }
    }

    /// @dev Recalls up to the harvestAmt from the active vault
    ///
    /// This function will recall less than harvestAmt if only less is available
    ///
    /// @param _recallAmt the amount to harvest from the active vault
    function _recallExcessFundsFromActiveVault(uint256 _recallAmt) internal {
        VaultWithIndirection.Data storage _activeVault = _vaults.last();
        uint256 activeVaultVal = _activeVault.totalValue();
        if (activeVaultVal < _recallAmt) {
            _recallAmt = activeVaultVal;
        }
        if (_recallAmt > 0) {
            _recallFundsFromActiveVault(_recallAmt);
        }
    }

    /// @dev Sets the address of the sentinel
    ///
    /// @param _sentinel address of the new sentinel
    function setSentinel(address _sentinel) external onlyGov() {
        require(_sentinel != ZERO_ADDRESS, "Transmuter: sentinel address cannot be 0x0.");
        sentinel = _sentinel;
        emit SentinelUpdated(_sentinel);
    }

    /// @dev Sets the threshold of total held funds above which excess funds will be planted in yield farms.
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _plantableThreshold the new plantable threshold.
    function setPlantableThreshold(uint256 _plantableThreshold) external onlyGov() {
        plantableThreshold = _plantableThreshold;
        emit PlantableThresholdUpdated(_plantableThreshold);
    }

    /// @dev Sets the plantableThreshold margin for triggering the planting or recalling of funds on harvest
    ///
    /// This function reverts if the caller is not the current governance.
    ///
    /// @param _plantableMargin the new plantable margin.
    function setPlantableMargin(uint256 _plantableMargin) external onlyGov() {
        plantableMargin = _plantableMargin;
        emit PlantableMarginUpdated(_plantableMargin);
    }

    /// @dev Sets if the contract should enter emergency exit mode.
    ///
    /// There are 2 main reasons to pause:
    ///     1. Need to shut down deposits in case of an emergency in one of the vaults
    ///     2. Need to migrate to a new transmuter
    ///
    /// While the transmuter is paused, deposit() and distribute() are disabled
    ///
    /// @param _pause if the contract should enter emergency exit mode.
    function setPause(bool _pause) external {
        require(msg.sender == governance || msg.sender == sentinel, "!(gov || sentinel)");
        pause = _pause;
        emit PauseUpdated(_pause);
    }

    /// @dev Harvests yield from a vault.
    ///
    /// @param _vaultId the identifier of the vault to harvest from.
    ///
    /// @return the amount of funds that were harvested from the vault.
    function harvest(uint256 _vaultId) external returns (uint256, uint256) {

        VaultWithIndirection.Data storage _vault = _vaults.get(_vaultId);

        (uint256 _harvestedAmount, uint256 _decreasedValue) = _vault.harvest(rewards);

        emit FundsHarvested(_harvestedAmount, _decreasedValue);

        return (_harvestedAmount, _decreasedValue);
    }

    /// @dev Sets the rewards contract.
    ///
    /// This function reverts if the new rewards contract is the zero address or the caller is not the current governance.
    ///
    /// @param _rewards the new rewards contract.
    function setRewards(address _rewards) external onlyGov() {
        // Check that the rewards address is not the zero address. Setting the rewards to the zero address would break
        // transfers to the address because of `safeTransfer` checks.
        require(_rewards != ZERO_ADDRESS, "Transmuter: rewards address cannot be 0x0.");

        rewards = _rewards;

        emit RewardsUpdated(_rewards);
    }

    /// @dev Migrates transmuter funds to a new transmuter
    ///
    /// @param migrateTo address of the new transmuter
    function migrateFunds(address migrateTo) external onlyGov() {
        require(migrateTo != address(0), "cannot migrate to 0x0");
        require(pause, "migrate: set emergency exit first");

        // leave enough funds to service any pending transmutations
        uint256 totalFunds = IERC20Burnable(token).balanceOf(address(this));
        uint256 migratableFunds = totalFunds.sub(totalSupplyAltokens, "not enough funds to service stakes");
        IERC20Burnable(token).approve(migrateTo, migratableFunds);
        ITransmuter(migrateTo).distribute(address(this), migratableFunds);
        emit MigrationComplete(migrateTo, migratableFunds);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

//import "hardhat/console.sol";
import  "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../interfaces/IVaultAdapter.sol";
import {IyVaultV2} from "../interfaces/IyVaultV2.sol";
import {YearnVaultAdapter} from "./YearnVaultAdapter.sol";

/// @title YearnVaultAdapter
///
/// @dev A vault adapter implementation which wraps a yEarn vault.
contract YearnVaultAdapterWithIndirection is YearnVaultAdapter {
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using SafeERC20Upgradeable for IDetailedERC20;
    using SafeERC20Upgradeable for IyVaultV2;
    using SafeMathUpgradeable for uint256;
    address public owner;

    function initialize() public override initializer{
        owner = msg.sender;
    }

    function setVaultAddress(IyVaultV2 _vault) public override {
        require(msg.sender == owner,"owner only able to initialize");
        YearnVaultAdapter.initialize() ;
        YearnVaultAdapter.setVaultAddress(_vault) ;
    }

    /// @dev Sends vault tokens to the recipient
    ///
    /// This function reverts if the caller is not the admin.
    ///
    /// @param _recipient the account to send the tokens to.
    /// @param _amount    the amount of tokens to send.
    function indirectWithdraw(address _recipient, uint256 _amount) external  {
        require(owner == msg.sender,"not a owner");
        vault.transfer(_recipient, _tokensToShares(_amount));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;

//import "hardhat/console.sol";
import  "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/Math.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/SafeERC20.sol";
//import  "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import {IDetailedERC20} from "../../interfaces/IDetailedERC20.sol";
import {YearnVaultAdapterWithIndirection} from "../../adapters/YearnVaultAdapterWithIndirection.sol";
//import "hardhat/console.sol";

/// @title Pool
///
/// @dev A library which provides the Vault data struct and associated functions.
library VaultWithIndirection {
  using VaultWithIndirection for Data;
  using VaultWithIndirection for List;
  using SafeERC20Upgradeable for IDetailedERC20;
  using SafeMathUpgradeable for uint256;
  struct Data {
    YearnVaultAdapterWithIndirection adapter;
    uint256 totalDeposited;
  }

  struct List {
    Data[] elements;
  }

  /// @dev Gets the total amount of assets deposited in the vault.
  ///
  /// @return the total assets.
  function totalValue(Data storage _self) internal view returns (uint256) {
    return _self.adapter.totalValue();
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token(Data storage _self) internal view returns (IDetailedERC20) {
    return IDetailedERC20(_self.adapter.token());
  }

  /// @dev Deposits funds from the caller into the vault.
  ///
  /// @param _amount the amount of funds to deposit.
  function deposit(Data storage _self, uint256 _amount) internal returns (uint256) {
    // Push the token that the vault accepts onto the stack to save gas.
    IDetailedERC20 _token = _self.token();

    _token.safeTransfer(address(_self.adapter), _amount);
    _self.adapter.deposit(_amount);
    _self.totalDeposited = _self.totalDeposited.add(_amount);

    return _amount;
  }

  /// @dev Deposits the entire token balance of the caller into the vault.
  function depositAll(Data storage _self) internal returns (uint256) {
    IDetailedERC20 _token = _self.token();
    return _self.deposit(_token.balanceOf(address(this)));
  }

  /// @dev Withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _self.directWithdraw(_recipient, _amount);
    _self.totalDeposited = _self.totalDeposited.sub(_decreasedValue);
    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Directly withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function directWithdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    IDetailedERC20 _token = _self.token();

    uint256 _startingBalance = _token.balanceOf(_recipient);
    uint256 _startingTotalValue = _self.totalValue();

    _self.adapter.withdraw(_recipient, _amount);

    uint256 _endingBalance = _token.balanceOf(_recipient);
    uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

    uint256 _endingTotalValue = _self.totalValue();
    uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Directly withdraw deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  /// @param _amount    the amount of tokens to withdraw.
  function indirectWithdraw(Data storage _self, address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    IDetailedERC20 _token = _self.token();

    uint256 _startingBalance = _token.balanceOf(_recipient);
    uint256 _startingTotalValue = _self.totalValue();

    _self.adapter.indirectWithdraw(_recipient, _amount);

    uint256 _endingBalance = _token.balanceOf(_recipient);
    uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

    uint256 _endingTotalValue = _self.totalValue();
    uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Withdraw all the deposited funds from the vault.
  ///
  /// @param _recipient the account to withdraw the tokens to.
  function withdrawAll(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    return _self.withdraw(_recipient, _self.totalDeposited);
  }

  /// @dev Harvests yield from the vault.
  ///
  /// @param _recipient the account to withdraw the harvested yield to.
  function harvest(Data storage _self, address _recipient) internal returns (uint256, uint256) {
    if (_self.totalValue() <= _self.totalDeposited) {
      return (0, 0);
    }
    uint256 _withdrawAmount = _self.totalValue().sub(_self.totalDeposited);
    return _self.indirectWithdraw(_recipient, _withdrawAmount);
  }

  /// @dev Adds a element to the list.
  ///
  /// @param _element the element to add.
  function push(List storage _self, Data memory _element) internal {
    _self.elements.push(_element);
  }

  /// @dev Gets a element from the list.
  ///
  /// @param _index the index in the list.
  ///
  /// @return the element at the specified index.
  function get(List storage _self, uint256 _index) internal view returns (Data storage) {
    return _self.elements[_index];
  }

  /// @dev Gets the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the last element in the list.
  function last(List storage _self) internal view returns (Data storage) {
    return _self.elements[_self.lastIndex()];
  }

  /// @dev Gets the index of the last element in the list.
  ///
  /// This function will revert if there are no elements in the list.
  ///
  /// @return the index of the last element.
  function lastIndex(List storage _self) internal view returns (uint256) {
    uint256 _length = _self.length();
    return _length.sub(1, "Vault.List: empty");
  }

  /// @dev Gets the number of elements in the list.
  ///
  /// @return the number of elements.
  function length(List storage _self) internal view returns (uint256) {
    return _self.elements.length;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;

interface ITransmuter  {
  function distribute (address origin, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12 ;

library FixedPointMath {
  uint256 public constant DECIMALS = 18;
  uint256 public constant SCALAR = 10**DECIMALS;

  struct FixedDecimal {
    uint256 x;
  }

  function fromU256(uint256 value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require(value == 0 || (x = value * SCALAR) / SCALAR == value);
    return FixedDecimal(x);
  }

  function maximumValue() internal pure returns (FixedDecimal memory) {
    return FixedDecimal(type(uint256).max);
  }

  function add(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require((x = self.x + value.x) >= self.x);
    return FixedDecimal(x);
  }

  function add(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    return add(self, fromU256(value));
  }

  function sub(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require((x = self.x - value.x) <= self.x);
    return FixedDecimal(x);
  }

  function sub(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    return sub(self, fromU256(value));
  }

  function mul(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    uint256 x;
    require(value == 0 || (x = self.x * value) / value == self.x);
    return FixedDecimal(x);
  }

  function div(FixedDecimal memory self, uint256 value) internal pure returns (FixedDecimal memory) {
    require(value != 0);
    return FixedDecimal(self.x / value);
  }

  function cmp(FixedDecimal memory self, FixedDecimal memory value) internal pure returns (int256) {
    if (self.x < value.x) {
      return -1;
    }

    if (self.x > value.x) {
      return 1;
    }

    return 0;
  }

  function decode(FixedDecimal memory self) internal pure returns (uint256) {
    return self.x / SCALAR;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20Upgradeable {
  function name() external returns (string memory);
  function symbol() external returns (string memory);
  function decimals() external returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;


import "./IDetailedERC20.sol";

/// Interface for all Vault Adapter implementations.
interface IVaultAdapter {

  /// @dev Gets the token that the adapter accepts.
  function token() external view returns (IDetailedERC20);

  /// @dev The total value of the assets deposited into the vault.
  function totalValue() external view returns (uint256);

  /// @dev Deposits funds into the vault.
  ///
  /// @param _amount  the amount of funds to deposit.
  function deposit(uint256 _amount) external;

  /// @dev Attempts to withdraw funds from the wrapped vault.
  ///
  /// The amount withdrawn to the recipient may be less than the amount requested.
  ///
  /// @param _recipient the recipient of the funds.
  /// @param _amount    the amount of funds to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;

import  "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IyVaultV2 is IERC20Upgradeable {
    function token() external view returns (address);
    function deposit() external returns (uint);
    function deposit(uint) external returns (uint);
    function deposit(uint, address) external returns (uint);
    function withdraw() external returns (uint);
    function withdraw(uint) external returns (uint);
    function withdraw(uint, address) external returns (uint);
    function withdraw(uint, address, uint) external returns (uint);
    function permit(address, address, uint, uint, bytes32) external view returns (bool);
    function pricePerShare() external view returns (uint);
    
    function apiVersion() external view returns (string memory);
    function totalAssets() external view returns (uint);
    function maxAvailableShares() external view returns (uint);
    function debtOutstanding() external view returns (uint);
    function debtOutstanding(address strategy) external view returns (uint);
    function creditAvailable() external view returns (uint);
    function creditAvailable(address strategy) external view returns (uint);
    function availableDepositLimit() external view returns (uint);
    function expectedReturn() external view returns (uint);
    function expectedReturn(address strategy) external view returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function balanceOf(address owner) external view override returns (uint);
    function totalSupply() external view override returns (uint);
    function governance() external view returns (address);
    function management() external view returns (address);
    function guardian() external view returns (address);
    function guestList() external view returns (address);
    function strategies(address) external view returns (uint, uint, uint, uint, uint, uint, uint, uint);
    function withdrawalQueue(uint) external view returns (address);
    function emergencyShutdown() external view returns (bool);
    function depositLimit() external view returns (uint);
    function debtRatio() external view returns (uint);
    function totalDebt() external view returns (uint);
    function lastReport() external view returns (uint);
    function activation() external view returns (uint);
    function rewards() external view returns (address);
    function managementFee() external view returns (uint);
    function performanceFee() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

//import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import  "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/SafeERC20.sol";
//import  "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapter} from "../interfaces/IVaultAdapter.sol";
import {IyVaultV2} from "../interfaces/IyVaultV2.sol";

/// @title YearnVaultAdapter
///
/// @dev A vault adapter implementation which wraps a yEarn vault.
contract YearnVaultAdapter is IVaultAdapter,Initializable {
  using FixedPointMath for FixedPointMath.FixedDecimal;
  using SafeERC20Upgradeable for IDetailedERC20;
  using SafeMathUpgradeable for uint256;

  /// @dev The vault that the adapter is wrapping.
  IyVaultV2 public vault;

  /// @dev The address which has admin control over this contract.
  address public admin;
     
  /// @dev A flag indicating if the contract has been initialized yet.
  bool public initialized;

  /// @dev The decimals of the token.
  uint256 public decimals;

  function setVaultAddress(IyVaultV2 _vault) public virtual onlyAdmin {
    vault = _vault;
    updateApproval();
    decimals = _vault.decimals();
  }

/// @dev Checks that the contract is in an initialized state.
  ///
  /// This is used over a modifier to reduce the size of the contract
  modifier expectInitialized() {
    require(initialized, "YearnVaultAdapter: not initialized.");
    _;
  }

  function initialize() public  virtual initializer{
    require(!initialized,"already initialized");
    admin = msg.sender;
    initialized = true;
  }

  /// @dev A modifier which reverts if the caller is not the admin.
  modifier onlyAdmin() {
    require(admin == msg.sender, "YearnVaultAdapter: only admin");
    _;
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token() external view override returns (IDetailedERC20) {
    return IDetailedERC20(vault.token());
  }

  /// @dev Gets the total value of the assets that the adapter holds in the vault.
  ///
  /// @return the total assets.
  function totalValue() external view override returns (uint256) {
    return _sharesToTokens(vault.balanceOf(address(this)));
  }

  /// @dev Deposits tokens into the vault.
  ///
  /// @param _amount the amount of tokens to deposit into the vault.
  function deposit(uint256 _amount) expectInitialized external override {
    vault.deposit(_amount);
  }

  /// @dev Withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(address _recipient, uint256 _amount) external override  expectInitialized onlyAdmin {
    vault.withdraw(_tokensToShares(_amount),_recipient);
  }

  /// @dev Updates the vaults approval of the token to be the maximum value.
  function updateApproval() public {
    address _token = vault.token();
    IDetailedERC20(_token).approve(address(vault), type(uint256).max);
  }

  /// @dev Computes the number of tokens an amount of shares is worth.
  ///
  /// @param _sharesAmount the amount of shares.
  ///
  /// @return the number of tokens the shares are worth.
  
  function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
    return _sharesAmount.mul(vault.pricePerShare()).div(10**decimals);
  }

  /// @dev Computes the number of shares an amount of tokens is worth.
  ///
  /// @param _tokensAmount the amount of shares.
  ///
  /// @return the number of shares the tokens are worth.
  function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
    return _tokensAmount.mul(10**decimals).div(vault.pricePerShare());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

