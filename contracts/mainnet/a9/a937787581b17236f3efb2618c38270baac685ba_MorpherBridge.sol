// ------------------------------------------------------------------------
// MorpherBridge
// Handles deposit to and withdraws from the side chain, writing of the merkle
// root to the main chain by the side chain operator, and enforces a rolling 24 hours
// token withdraw limit from side chain to main chain.
// If side chain operator doesn't write a merkle root hash to main chain for more than
// 72 hours positions and balaces from side chain can be transferred to main chain.
// ------------------------------------------------------------------------

pragma solidity 0.5.16;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IMorpherState.sol";
import "./MerkleProof.sol";

contract MorpherBridge is Ownable {

    IMorpherState state;
    using SafeMath for uint256;

    mapping(address => mapping(uint256 => uint256)) withdrawalPerDay; //[address][day] = withdrawalAmount
    mapping(address => mapping(uint256 => uint256)) withdrawalPerMonth; //[address][month] = withdrawalAmount

    uint256 public withdrawalLimitDaily = 200000 * (10**18); //200k MPH per day
    uint256 public withdrawalLimitMonthly = 1000000 * (10 ** 18); //1M MPH per month

    event TransferToLinkedChain(
        address indexed from,
        uint256 tokens,
        uint256 totalTokenSent,
        uint256 timeStamp,
        uint256 transferNonce,
        bytes32 indexed transferHash
    );
    event TrustlessWithdrawFromSideChain(address indexed from, uint256 tokens);
    event OperatorChainTransfer(address indexed from, uint256 tokens, bytes32 sidechainTransactionHash);
    event ClaimFailedTransferToSidechain(address indexed from, uint256 tokens);
    event PositionRecoveryFromSideChain(address indexed from, bytes32 positionHash);
    event TokenRecoveryFromSideChain(address indexed from, bytes32 positionHash);
    event SideChainMerkleRootUpdated(bytes32 _rootHash);
    event WithdrawLimitReset();
    event WithdrawLimitChanged(uint256 _withdrawLimit);
    event WithdrawLimitDailyChanged(uint256 _oldLimit, uint256 _newLimit);
    event WithdrawLimitMonthlyChanged(uint256 _oldLimit, uint256 _newLimit);
    event LinkState(address _address);

    constructor(address _stateAddress, address _coldStorageOwnerAddress) public {
        setMorpherState(_stateAddress);
        transferOwnership(_coldStorageOwnerAddress);
    }

    modifier onlySideChainOperator {
        require(msg.sender == state.getSideChainOperator(), "MorpherBridge: Function can only be called by Sidechain Operator.");
        _;
    }

    modifier sideChainInactive {
        require(now - state.inactivityPeriod() > state.getSideChainMerkleRootWrittenAtTime(), "MorpherBridge: Function can only be called if sidechain is inactive.");
        _;
    }
    
    modifier fastTransfers {
        require(state.fastTransfersEnabled() == true, "MorpherBridge: Fast transfers have been disabled permanently.");
        _;
    }

    modifier onlyMainchain {
        require(state.mainChain() == true, "MorpherBridge: Function can only be executed on Ethereum." );
        _;
    }
    
    // ------------------------------------------------------------------------
    // Links Token Contract with State
    // ------------------------------------------------------------------------
    function setMorpherState(address _stateAddress) public onlyOwner {
        state = IMorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    function setInactivityPeriod(uint256 _periodInSeconds) private {
        state.setInactivityPeriod(_periodInSeconds);
    }

    function disableFastTransfers() public onlyOwner  {
        state.disableFastWithdraws();
    }

    function updateSideChainMerkleRoot(bytes32 _rootHash) public onlySideChainOperator {
        state.setSideChainMerkleRoot(_rootHash);
        emit SideChainMerkleRootUpdated(_rootHash);
    }

    function resetLast24HoursAmountWithdrawn() public onlySideChainOperator {
        state.resetLast24HoursAmountWithdrawn();
        emit WithdrawLimitReset();
    }

    function set24HourWithdrawLimit(uint256 _withdrawLimit) public onlySideChainOperator {
        state.set24HourWithdrawLimit(_withdrawLimit);
        emit WithdrawLimitChanged(_withdrawLimit);
    }

    function updateWithdrawLimitDaily(uint256 _withdrawLimit) public onlySideChainOperator {
        emit WithdrawLimitDailyChanged(withdrawalLimitDaily, _withdrawLimit);
        withdrawalLimitDaily = _withdrawLimit;
    }

    function updateWithdrawLimitMonthly(uint256 _withdrawLimit) public onlySideChainOperator {
        emit WithdrawLimitMonthlyChanged(withdrawalLimitMonthly, _withdrawLimit);
        withdrawalLimitMonthly = _withdrawLimit;
    }

    function getTokenSentToLinkedChain(address _address) public view returns (uint256 _token) {
        return state.getTokenSentToLinkedChain(_address);
    }

    function getTokenClaimedOnThisChain(address _address) public view returns (uint256 _token)  {
        return state.getTokenClaimedOnThisChain(_address);
    }

    function getTokenSentToLinkedChainTime(address _address) public view returns (uint256 _time)  {
        return state.getTokenSentToLinkedChainTime(_address);
    }

    // ------------------------------------------------------------------------
    // verifyWithdrawOk(uint256 _amount)
    // Checks if creating _amount token on main chain does not violate the 24 hour transfer limit
    // ------------------------------------------------------------------------
    function verifyWithdrawOk(uint256 _amount) public returns (bool _authorized) {
        uint256 _lastWithdrawLimitReductionTime = state.lastWithdrawLimitReductionTime();
        uint256 _withdrawLimit24Hours = state.withdrawLimit24Hours();
        
        if (now > _lastWithdrawLimitReductionTime) {
            uint256 _timePassed = now.sub(_lastWithdrawLimitReductionTime);
            state.update24HoursWithdrawLimit(_timePassed.mul(_withdrawLimit24Hours).div(1 days));
        }
        
        if (state.last24HoursAmountWithdrawn().add(_amount) <= _withdrawLimit24Hours) {
            return true;
        } else {
            return false;
        }
    }

    function isNotDailyLimitExceeding(uint256 _amount) public view returns(bool) {
        return (withdrawalPerDay[msg.sender][block.timestamp / 1 days].add(_amount) <= withdrawalLimitDaily);
    }
    function isNotMonthlyLimitExceeding(uint256 _amount) public view returns(bool) {
        return (withdrawalPerMonth[msg.sender][block.timestamp / 30 days].add(_amount) <= withdrawalLimitMonthly);
    }

    function verifyUpdateDailyLimit(uint256 _amount) public {
        require(isNotDailyLimitExceeding(_amount), "MorpherBridge: Withdrawal Amount exceeds daily limit");
        withdrawalPerDay[msg.sender][block.timestamp / 1 days] = withdrawalPerDay[msg.sender][block.timestamp / 1 days].add(_amount);
    }

    function verifyUpdateMonthlyLimit(uint256 _amount) public {
        require(isNotMonthlyLimitExceeding(_amount), "MorpherBridge: Withdrawal Amount exceeds monthly limit");
        withdrawalPerMonth[msg.sender][block.timestamp / 30 days] = withdrawalPerMonth[msg.sender][block.timestamp / 30 days].add(_amount);
    }

    // ------------------------------------------------------------------------
    // transferToSideChain(uint256 _tokens)
    // Transfer token to Morpher's side chain to trade without fees and near instant
    // settlement.
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are not supported
    // Token are burned on the main chain and are created and credited to msg.sender
    //  on the side chain
    // ------------------------------------------------------------------------
    function transferToSideChain(uint256 _tokens) public {
        require(_tokens >= 0, "MorpherBridge: Amount of tokens must be positive.");
        require(state.balanceOf(msg.sender) >= _tokens, "MorpherBridge: Insufficient balance.");
        state.burn(msg.sender, _tokens);
        uint256 _newTokenSentToLinkedChain = getTokenSentToLinkedChain(msg.sender).add(_tokens);
        uint256 _transferNonce = state.getBridgeNonce();
        uint256 _timeStamp = now;
        bytes32 _transferHash = keccak256(
            abi.encodePacked(
                msg.sender,
                _tokens,
                _newTokenSentToLinkedChain,
                _timeStamp,
                _transferNonce
            )
        );
        state.setTokenSentToLinkedChain(msg.sender, _newTokenSentToLinkedChain);
        emit TransferToLinkedChain(msg.sender, _tokens, _newTokenSentToLinkedChain, _timeStamp, _transferNonce, _transferHash);
    }

    // ------------------------------------------------------------------------
    // fastTransferFromSideChain(uint256 _numOfToken, uint256 _tokenBurnedOnLinkedChain, bytes32[] memory _proof)
    // The sidechain operator can credit users with token they burend on the sidechain. Transfers
    // happen immediately. To be removed after Beta.
    // ------------------------------------------------------------------------
    function fastTransferFromSideChain(address _address, uint256 _numOfToken, uint256 _tokenBurnedOnLinkedChain, bytes32 _sidechainTransactionHash) public onlySideChainOperator fastTransfers {
        uint256 _tokenClaimed = state.getTokenClaimedOnThisChain(_address);
        require(verifyWithdrawOk(_numOfToken), "MorpherBridge: Withdraw amount exceeds permitted 24 hour limit. Please try again in a few hours.");
        require(_tokenClaimed.add(_numOfToken) <= _tokenBurnedOnLinkedChain, "MorpherBridge: Token amount exceeds token deleted on linked chain.");
        _chainTransfer(_address, _tokenClaimed, _numOfToken);
        emit OperatorChainTransfer(_address, _numOfToken, _sidechainTransactionHash);
    }
    
    // ------------------------------------------------------------------------
    // trustlessTransferFromSideChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof)
    // Performs a merkle proof on the number of token that have been burned by the user on the side chain.
    // If the number of token claimed on the main chain is less than the number of burned token on the side chain
    // the difference (or less) can be claimed on the main chain.
    // ------------------------------------------------------------------------
    function trustlessTransferFromLinkedChain(uint256 _numOfToken, uint256 _claimLimit, bytes32[] memory _proof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _claimLimit));
        uint256 _tokenClaimed = state.getTokenClaimedOnThisChain(msg.sender);        
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Please make sure you entered the correct claim limit.");
        require(verifyWithdrawOk(_numOfToken), "MorpherBridge: Withdraw amount exceeds permitted 24 hour limit. Please try again in a few hours.");
        verifyUpdateDailyLimit(_numOfToken);
        verifyUpdateMonthlyLimit(_numOfToken);
        require(_tokenClaimed.add(_numOfToken) <= _claimLimit, "MorpherBridge: Token amount exceeds token deleted on linked chain.");     
        _chainTransfer(msg.sender, _tokenClaimed, _numOfToken);   
        emit TrustlessWithdrawFromSideChain(msg.sender, _numOfToken);
    }
    
    // ------------------------------------------------------------------------
    // _chainTransfer(address _address, uint256 _tokenClaimed, uint256 _numOfToken)
    // Creates token on the chain for the user after proving their distruction on the 
    // linked chain has been proven before 
    // ------------------------------------------------------------------------
    function _chainTransfer(address _address, uint256 _tokenClaimed, uint256 _numOfToken) private {
        state.setTokenClaimedOnThisChain(_address, _tokenClaimed.add(_numOfToken));
        state.add24HoursWithdrawn(_numOfToken);
        state.mint(_address, _numOfToken);
    }
        
    // ------------------------------------------------------------------------
    // claimFailedTransferToSidechain(uint256 _wrongSideChainBalance, bytes32[] memory _proof)
    // If token sent to side chain were not credited to the user on the side chain within inactivityPeriod
    // they can reclaim the token on the main chain by submitting the proof that their
    // side chain balance is less than the number of token sent from main chain.
    // ------------------------------------------------------------------------
    function claimFailedTransferToSidechain(uint256 _wrongSideChainBalance, bytes32[] memory _proof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wrongSideChainBalance));
        uint256 _tokenSentToLinkedChain = getTokenSentToLinkedChain(msg.sender);
        uint256 _tokenSentToLinkedChainTime = getTokenSentToLinkedChainTime(msg.sender);
        uint256 _inactivityPeriod = state.inactivityPeriod();
        
        require(now > _tokenSentToLinkedChainTime.add(_inactivityPeriod), "MorpherBridge: Failed deposits can only be claimed after inactivity period.");
        require(_wrongSideChainBalance < _tokenSentToLinkedChain, "MorpherBridge: Other chain credit is greater equal to wrongSideChainBalance.");
        require(verifyWithdrawOk(_tokenSentToLinkedChain.sub(_wrongSideChainBalance)), "MorpherBridge: Claim amount exceeds permitted 24 hour limit.");
        require(mProof(_proof, leaf), "MorpherBridge: Merkle Proof failed. Enter total amount of deposits on side chain.");
        
        uint256 _claimAmount = _tokenSentToLinkedChain.sub(_wrongSideChainBalance);
        state.setTokenSentToLinkedChain(msg.sender, _tokenSentToLinkedChain.sub(_claimAmount));
        state.add24HoursWithdrawn(_claimAmount);
        state.mint(msg.sender, _claimAmount);
        emit ClaimFailedTransferToSidechain(msg.sender, _claimAmount);
    }

    // ------------------------------------------------------------------------
    // recoverPositionFromSideChain(bytes32[] memory _proof, bytes32 _leaf, bytes32 _marketId, uint256 _timeStamp, uint256 _longShares, uint256 _shortShares, uint256 _meanEntryPrice, uint256 _meanEntrySpread, uint256 _meanEntryLeverage)
    // Failsafe against side chain operator becoming inactive or withholding Times (Time withhold attack).
    // After 72 hours of no update of the side chain merkle root users can withdraw their last recorded
    // positions from side chain to main chain. Overwrites eventually existing position on main chain.
    // ------------------------------------------------------------------------
    function recoverPositionFromSideChain(
        bytes32[] memory _proof,
        bytes32 _leaf,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
        ) public sideChainInactive onlyMainchain {
        require(_leaf == state.getPositionHash(msg.sender, _marketId, _timeStamp, _longShares, _shortShares, _meanEntryPrice, _meanEntrySpread, _meanEntryLeverage, _liquidationPrice), "MorpherBridge: leaf does not equal position hash.");
        require(state.getPositionClaimedOnMainChain(_leaf) == false, "MorpherBridge: Position already transferred.");
        require(mProof(_proof,_leaf) == true, "MorpherBridge: Merkle proof failed.");
        state.setPositionClaimedOnMainChain(_leaf);
        state.setPosition(msg.sender, _marketId, _timeStamp, _longShares, _shortShares, _meanEntryPrice, _meanEntrySpread, _meanEntryLeverage, _liquidationPrice);
        emit PositionRecoveryFromSideChain(msg.sender, _leaf);
        // Remark: After resuming operations side chain operator has 72 hours to sync and eliminate transferred positions on side chain to avoid double spend
    }

    // ------------------------------------------------------------------------
    // recoverTokenFromSideChain(bytes32[] memory _proof, bytes32 _leaf, bytes32 _marketId, uint256 _timeStamp, uint256 _longShares, uint256 _shortShares, uint256 _meanEntryPrice, uint256 _meanEntrySpread, uint256 _meanEntryLeverage)
    // Failsafe against side chain operator becoming inactive or withholding times (time withhold attack).
    // After 72 hours of no update of the side chain merkle root users can withdraw their last recorded
    // token balance from side chain to main chain.
    // ------------------------------------------------------------------------
    function recoverTokenFromSideChain(bytes32[] memory _proof, bytes32 _leaf, uint256 _balance) public sideChainInactive onlyMainchain {
        // Require side chain root hash not set on Mainchain for more than 72 hours (=3 days)
        require(_leaf == state.getBalanceHash(msg.sender, _balance), "MorpherBridge: Wrong balance.");
        require(state.getPositionClaimedOnMainChain(_leaf) == false, "MorpherBridge: Token already transferred.");
        require(mProof(_proof,_leaf) == true, "MorpherBridge: Merkle proof failed.");
        require(verifyWithdrawOk(_balance), "MorpherBridge: Withdraw amount exceeds permitted 24 hour limit.");
        state.setPositionClaimedOnMainChain(_leaf);
        _chainTransfer(msg.sender, state.getTokenClaimedOnThisChain(msg.sender), _balance);
        emit TokenRecoveryFromSideChain(msg.sender, _leaf);
        // Remark: Side chain operator must adjust side chain balances for token recoveries before restarting operations to avoid double spend
    }

    // ------------------------------------------------------------------------
    // mProof(bytes32[] memory _proof, bytes32 _leaf)
    // Computes merkle proof against the root hash of the sidechain stored in Morpher state
    // ------------------------------------------------------------------------
    function mProof(bytes32[] memory _proof, bytes32 _leaf) public view returns(bool _isTrue) {
        return MerkleProof.verify(_proof, state.getSideChainMerkleRoot(), _leaf);
    }
}