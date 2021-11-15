/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "../capital/Pool.sol";
import "../claims/ClaimsReward.sol";
import "../token/NXMToken.sol";
import "../token/TokenController.sol";
import "../token/TokenFunctions.sol";
import "./ClaimsData.sol";
import "./Incidents.sol";

contract Claims is Iupgradable {
  using SafeMath for uint;

  TokenController internal tc;
  ClaimsReward internal cr;
  Pool internal p1;
  ClaimsData internal cd;
  TokenData internal td;
  QuotationData internal qd;
  Incidents internal incidents;

  uint private constant DECIMAL1E18 = uint(10) ** 18;

  /**
   * @dev Sets the status of claim using claim id.
   * @param claimId claim id.
   * @param stat status to be set.
   */
  function setClaimStatus(uint claimId, uint stat) external onlyInternal {
    _setClaimStatus(claimId, stat);
  }

  /**
   * @dev Calculates total amount that has been used to assess a claim.
   * Computaion:Adds acceptCA(tokens used for voting in favor of a claim)
   * denyCA(tokens used for voting against a claim) *  current token price.
   * @param claimId Claim Id.
   * @param member Member type 0 -> Claim Assessors, else members.
   * @return tokens Total Amount used in Claims assessment.
   */
  function getCATokens(uint claimId, uint member) external view returns (uint tokens) {
    uint coverId;
    (, coverId) = cd.getClaimCoverId(claimId);

    bytes4 currency = qd.getCurrencyOfCover(coverId);
    address asset = cr.getCurrencyAssetAddress(currency);
    uint tokenx1e18 = p1.getTokenPrice(asset);

    uint accept;
    uint deny;
    if (member == 0) {
      (, accept, deny) = cd.getClaimsTokenCA(claimId);
    } else {
      (, accept, deny) = cd.getClaimsTokenMV(claimId);
    }
    tokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18); // amount (not in tokens)
  }

  /**
   * Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public onlyInternal {
    td = TokenData(ms.getLatestAddress("TD"));
    tc = TokenController(ms.getLatestAddress("TC"));
    p1 = Pool(ms.getLatestAddress("P1"));
    cr = ClaimsReward(ms.getLatestAddress("CR"));
    cd = ClaimsData(ms.getLatestAddress("CD"));
    qd = QuotationData(ms.getLatestAddress("QD"));
    incidents = Incidents(ms.getLatestAddress("IC"));
  }

  /**
   * @dev Submits a claim for a given cover note.
   * Adds claim to queue incase of emergency pause else directly submits the claim.
   * @param coverId Cover Id.
   */
  function submitClaim(uint coverId) external {
    _submitClaim(coverId, msg.sender);
  }

  function submitClaimForMember(uint coverId, address member) external onlyInternal {
    _submitClaim(coverId, member);
  }

  function _submitClaim(uint coverId, address member) internal {

    require(!ms.isPause(), "Claims: System is paused");

    (/* id */, address contractAddress) = qd.getscAddressOfCover(coverId);
    address token = incidents.coveredToken(contractAddress);
    require(token == address(0), "Claims: Product type does not allow claims");

    address coverOwner = qd.getCoverMemberAddress(coverId);
    require(coverOwner == member, "Claims: Not cover owner");

    uint expirationDate = qd.getValidityOfCover(coverId);
    uint gracePeriod = tc.claimSubmissionGracePeriod();
    require(expirationDate.add(gracePeriod) > now, "Claims: Grace period has expired");

    tc.markCoverClaimOpen(coverId);
    qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.ClaimSubmitted));

    uint claimId = cd.actualClaimLength();
    cd.addClaim(claimId, coverId, coverOwner, now);
    cd.callClaimEvent(coverId, coverOwner, claimId, now);
  }

  // solhint-disable-next-line no-empty-blocks
  function submitClaimAfterEPOff() external pure {}

  /**
   * @dev Castes vote for members who have tokens locked under Claims Assessment
   * @param claimId  claim id.
   * @param verdict 1 for Accept,-1 for Deny.
   */
  function submitCAVote(uint claimId, int8 verdict) public isMemberAndcheckPause {
    require(checkVoteClosing(claimId) != 1);
    require(cd.userClaimVotePausedOn(msg.sender).add(cd.pauseDaysCA()) < now);
    uint tokens = tc.tokensLockedAtTime(msg.sender, "CLA", now.add(cd.claimDepositTime()));
    require(tokens > 0);
    uint stat;
    (, stat) = cd.getClaimStatusNumber(claimId);
    require(stat == 0);
    require(cd.getUserClaimVoteCA(msg.sender, claimId) == 0);
    td.bookCATokens(msg.sender);
    cd.addVote(msg.sender, tokens, claimId, verdict);
    cd.callVoteEvent(msg.sender, claimId, "CAV", tokens, now, verdict);
    uint voteLength = cd.getAllVoteLength();
    cd.addClaimVoteCA(claimId, voteLength);
    cd.setUserClaimVoteCA(msg.sender, claimId, voteLength);
    cd.setClaimTokensCA(claimId, verdict, tokens);
    tc.extendLockOf(msg.sender, "CLA", td.lockCADays());
    int close = checkVoteClosing(claimId);
    if (close == 1) {
      cr.changeClaimStatus(claimId);
    }
  }

  /**
   * @dev Submits a member vote for assessing a claim.
   * Tokens other than those locked under Claims
   * Assessment can be used to cast a vote for a given claim id.
   * @param claimId Selected claim id.
   * @param verdict 1 for Accept,-1 for Deny.
   */
  function submitMemberVote(uint claimId, int8 verdict) public isMemberAndcheckPause {
    require(checkVoteClosing(claimId) != 1);
    uint stat;
    uint tokens = tc.totalBalanceOf(msg.sender);
    (, stat) = cd.getClaimStatusNumber(claimId);
    require(stat >= 1 && stat <= 5);
    require(cd.getUserClaimVoteMember(msg.sender, claimId) == 0);
    cd.addVote(msg.sender, tokens, claimId, verdict);
    cd.callVoteEvent(msg.sender, claimId, "MV", tokens, now, verdict);
    tc.lockForMemberVote(msg.sender, td.lockMVDays());
    uint voteLength = cd.getAllVoteLength();
    cd.addClaimVotemember(claimId, voteLength);
    cd.setUserClaimVoteMember(msg.sender, claimId, voteLength);
    cd.setClaimTokensMV(claimId, verdict, tokens);
    int close = checkVoteClosing(claimId);
    if (close == 1) {
      cr.changeClaimStatus(claimId);
    }
  }

  // solhint-disable-next-line no-empty-blocks
  function pauseAllPendingClaimsVoting() external pure {}

  // solhint-disable-next-line no-empty-blocks
  function startAllPendingClaimsVoting() external pure {}

  /**
   * @dev Checks if voting of a claim should be closed or not.
   * @param claimId Claim Id.
   * @return close 1 -> voting should be closed, 0 -> if voting should not be closed,
   * -1 -> voting has already been closed.
   */
  function checkVoteClosing(uint claimId) public view returns (int8 close) {
    close = 0;
    uint status;
    (, status) = cd.getClaimStatusNumber(claimId);
    uint dateUpd = cd.getClaimDateUpd(claimId);
    if (status == 12 && dateUpd.add(cd.payoutRetryTime()) < now) {
      if (cd.getClaimState12Count(claimId) < 60)
        close = 1;
    }

    if (status > 5 && status != 12) {
      close = - 1;
    } else if (status != 12 && dateUpd.add(cd.maxVotingTime()) <= now) {
      close = 1;
    } else if (status != 12 && dateUpd.add(cd.minVotingTime()) >= now) {
      close = 0;
    } else if (status == 0 || (status >= 1 && status <= 5)) {
      close = _checkVoteClosingFinal(claimId, status);
    }

  }

  /**
   * @dev Checks if voting of a claim should be closed or not.
   * Internally called by checkVoteClosing method
   * for Claims whose status number is 0 or status number lie between 2 and 6.
   * @param claimId Claim Id.
   * @param status Current status of claim.
   * @return close 1 if voting should be closed,0 in case voting should not be closed,
   * -1 if voting has already been closed.
   */
  function _checkVoteClosingFinal(uint claimId, uint status) internal view returns (int8 close) {
    close = 0;
    uint coverId;
    (, coverId) = cd.getClaimCoverId(claimId);

    bytes4 currency = qd.getCurrencyOfCover(coverId);
    address asset = cr.getCurrencyAssetAddress(currency);
    uint tokenx1e18 = p1.getTokenPrice(asset);

    uint accept;
    uint deny;
    (, accept, deny) = cd.getClaimsTokenCA(claimId);
    uint caTokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18);
    (, accept, deny) = cd.getClaimsTokenMV(claimId);
    uint mvTokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18);
    uint sumassured = qd.getCoverSumAssured(coverId).mul(DECIMAL1E18);
    if (status == 0 && caTokens >= sumassured.mul(10)) {
      close = 1;
    } else if (status >= 1 && status <= 5 && mvTokens >= sumassured.mul(10)) {
      close = 1;
    }
  }

  /**
   * @dev Changes the status of an existing claim id, based on current
   * status and current conditions of the system
   * @param claimId Claim Id.
   * @param stat status number.
   */
  function _setClaimStatus(uint claimId, uint stat) internal {

    uint origstat;
    uint state12Count;
    uint dateUpd;
    uint coverId;
    (, coverId, , origstat, dateUpd, state12Count) = cd.getClaim(claimId);
    (, origstat) = cd.getClaimStatusNumber(claimId);

    if (stat == 12 && origstat == 12) {
      cd.updateState12Count(claimId, 1);
    }
    cd.setClaimStatus(claimId, stat);

    if (state12Count >= 60 && stat == 12) {
      cd.setClaimStatus(claimId, 13);
      qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.ClaimDenied));
    }

    cd.setClaimdateUpd(claimId, now);
  }

}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../abstract/MasterAware.sol";
import "../../interfaces/IPool.sol";
import "../cover/Quotation.sol";
import "../oracles/PriceFeedOracle.sol";
import "../token/NXMToken.sol";
import "../token/TokenController.sol";
import "./MCR.sol";

contract Pool is IPool, MasterAware, ReentrancyGuard {
  using Address for address;
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  struct AssetData {
    uint112 minAmount;
    uint112 maxAmount;
    uint32 lastSwapTime;
    // 18 decimals of precision. 0.01% -> 0.0001 -> 1e14
    uint maxSlippageRatio;
  }

  /* storage */
  address[] public assets;
  mapping(address => AssetData) public assetData;

  // contracts
  Quotation public quotation;
  NXMToken public nxmToken;
  TokenController public tokenController;
  MCR public mcr;

  // parameters
  address public swapController;
  uint public minPoolEth;
  PriceFeedOracle public priceFeedOracle;
  address public swapOperator;

  /* constants */
  address constant public ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  uint public constant MCR_RATIO_DECIMALS = 4;
  uint public constant MAX_MCR_RATIO = 40000; // 400%
  uint public constant MAX_BUY_SELL_MCR_ETH_FRACTION = 500; // 5%. 4 decimal points

  uint internal constant CONSTANT_C = 5800000;
  uint internal constant CONSTANT_A = 1028 * 1e13;
  uint internal constant TOKEN_EXPONENT = 4;

  /* events */
  event Payout(address indexed to, address indexed asset, uint amount);
  event NXMSold (address indexed member, uint nxmIn, uint ethOut);
  event NXMBought (address indexed member, uint ethIn, uint nxmOut);
  event Swapped(address indexed fromAsset, address indexed toAsset, uint amountIn, uint amountOut);

  /* logic */
  modifier onlySwapOperator {
    require(msg.sender == swapOperator, "Pool: not swapOperator");
    _;
  }

  constructor (
    address[] memory _assets,
    uint112[] memory _minAmounts,
    uint112[] memory _maxAmounts,
    uint[] memory _maxSlippageRatios,
    address _master,
    address _priceOracle,
    address _swapOperator
  ) public {

    require(_assets.length == _minAmounts.length, "Pool: length mismatch");
    require(_assets.length == _maxAmounts.length, "Pool: length mismatch");
    require(_assets.length == _maxSlippageRatios.length, "Pool: length mismatch");

    for (uint i = 0; i < _assets.length; i++) {

      address asset = _assets[i];
      require(asset != address(0), "Pool: asset is zero address");
      require(_maxAmounts[i] >= _minAmounts[i], "Pool: max < min");
      require(_maxSlippageRatios[i] <= 1 ether, "Pool: max < min");

      assets.push(asset);
      assetData[asset].minAmount = _minAmounts[i];
      assetData[asset].maxAmount = _maxAmounts[i];
      assetData[asset].maxSlippageRatio = _maxSlippageRatios[i];
    }

    master = INXMMaster(_master);
    priceFeedOracle = PriceFeedOracle(_priceOracle);
    swapOperator = _swapOperator;
  }

  // fallback function
  function() external payable {}

  // for legacy Pool1 upgrade compatibility
  function sendEther() external payable {}

  /**
   * @dev Calculates total value of all pool assets in ether
   */
  function getPoolValueInEth() public view returns (uint) {

    uint total = address(this).balance;

    for (uint i = 0; i < assets.length; i++) {

      address assetAddress = assets[i];
      IERC20 token = IERC20(assetAddress);

      uint rate = priceFeedOracle.getAssetToEthRate(assetAddress);
      require(rate > 0, "Pool: zero rate");

      uint assetBalance = token.balanceOf(address(this));
      uint assetValue = assetBalance.mul(rate).div(1e18);

      total = total.add(assetValue);
    }

    return total;
  }

  /* asset related functions */

  function getAssets() external view returns (address[] memory) {
    return assets;
  }

  function getAssetDetails(address _asset) external view returns (
    uint112 min,
    uint112 max,
    uint32 lastAssetSwapTime,
    uint maxSlippageRatio
  ) {

    AssetData memory data = assetData[_asset];

    return (data.minAmount, data.maxAmount, data.lastSwapTime, data.maxSlippageRatio);
  }

  function addAsset(
    address _asset,
    uint112 _min,
    uint112 _max,
    uint _maxSlippageRatio
  ) external onlyGovernance {

    require(_asset != address(0), "Pool: asset is zero address");
    require(_max >= _min, "Pool: max < min");
    require(_maxSlippageRatio <= 1 ether, "Pool: max slippage ratio > 1");

    for (uint i = 0; i < assets.length; i++) {
      require(_asset != assets[i], "Pool: asset exists");
    }

    assets.push(_asset);
    assetData[_asset] = AssetData(_min, _max, 0, _maxSlippageRatio);
  }

  function removeAsset(address _asset) external onlyGovernance {

    for (uint i = 0; i < assets.length; i++) {

      if (_asset != assets[i]) {
        continue;
      }

      delete assetData[_asset];
      assets[i] = assets[assets.length - 1];
      assets.pop();

      return;
    }

    revert("Pool: asset not found");
  }

  function setAssetDetails(
    address _asset,
    uint112 _min,
    uint112 _max,
    uint _maxSlippageRatio
  ) external onlyGovernance {

    require(_min <= _max, "Pool: min > max");
    require(_maxSlippageRatio <= 1 ether, "Pool: max slippage ratio > 1");

    for (uint i = 0; i < assets.length; i++) {

      if (_asset != assets[i]) {
        continue;
      }

      assetData[_asset].minAmount = _min;
      assetData[_asset].maxAmount = _max;
      assetData[_asset].maxSlippageRatio = _maxSlippageRatio;

      return;
    }

    revert("Pool: asset not found");
  }

  /* claim related functions */

  /**
   * @dev Execute the payout in case a claim is accepted
   * @param asset token address or 0xEee...EEeE for ether
   * @param payoutAddress send funds to this address
   * @param amount amount to send
   */
  function sendClaimPayout (
    address asset,
    address payable payoutAddress,
    uint amount
  ) external onlyInternal nonReentrant returns (bool success) {

    bool ok;

    if (asset == ETH) {
      // solhint-disable-next-line avoid-low-level-calls
      (ok, /* data */) = payoutAddress.call.value(amount)("");
    } else {
      ok =  _safeTokenTransfer(asset, payoutAddress, amount);
    }

    if (ok) {
      emit Payout(payoutAddress, asset, amount);
    }

    return ok;
  }

  /**
   * @dev safeTransfer implementation that does not revert
   * @param tokenAddress ERC20 address
   * @param to destination
   * @param value amount to send
   * @return success true if the transfer was successfull
   */
  function _safeTokenTransfer (
    address tokenAddress,
    address to,
    uint256 value
  ) internal returns (bool) {

    // token address is not a contract
    if (!tokenAddress.isContract()) {
      return false;
    }

    IERC20 token = IERC20(tokenAddress);
    bytes memory data = abi.encodeWithSelector(token.transfer.selector, to, value);
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = tokenAddress.call(data);

    // low-level call failed/reverted
    if (!success) {
      return false;
    }

    // tokens that don't have return data
    if (returndata.length == 0) {
      return true;
    }

    // tokens that have return data will return a bool
    return abi.decode(returndata, (bool));
  }

  /* pool lifecycle functions */

  function transferAsset(
    address asset,
    address payable destination,
    uint amount
  ) external onlyGovernance nonReentrant {

    require(assetData[asset].maxAmount == 0, "Pool: max not zero");
    require(destination != address(0), "Pool: dest zero");

    IERC20 token = IERC20(asset);
    uint balance = token.balanceOf(address(this));
    uint transferableAmount = amount > balance ? balance : amount;

    token.safeTransfer(destination, transferableAmount);
  }

  function upgradeCapitalPool(address payable newPoolAddress) external onlyMaster nonReentrant {

    // transfer ether
    uint ethBalance = address(this).balance;
    (bool ok, /* data */) = newPoolAddress.call.value(ethBalance)("");
    require(ok, "Pool: transfer failed");

    // transfer assets
    for (uint i = 0; i < assets.length; i++) {
      IERC20 token = IERC20(assets[i]);
      uint tokenBalance = token.balanceOf(address(this));
      token.safeTransfer(newPoolAddress, tokenBalance);
    }

  }

  /**
   * @dev Update dependent contract address
   * @dev Implements MasterAware interface function
   */
  function changeDependentContractAddress() public {
    nxmToken = NXMToken(master.tokenAddress());
    tokenController = TokenController(master.getLatestAddress("TC"));
    quotation = Quotation(master.getLatestAddress("QT"));
    mcr = MCR(master.getLatestAddress("MC"));
  }

  /* cover purchase functions */

  /// @dev Enables user to purchase cover with funding in ETH.
  /// @param smartCAdd Smart Contract Address
  function makeCoverBegin(
    address smartCAdd,
    bytes4 coverCurr,
    uint[] memory coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public payable onlyMember whenNotPaused {

    require(coverCurr == "ETH", "Pool: Unexpected asset type");
    require(msg.value == coverDetails[1], "Pool: ETH amount does not match premium");

    quotation.verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
  }

  /**
   * @dev Enables user to purchase cover via currency asset eg DAI
   */
  function makeCoverUsingCA(
    address smartCAdd,
    bytes4 coverCurr,
    uint[] memory coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public onlyMember whenNotPaused {
    require(coverCurr != "ETH", "Pool: Unexpected asset type");
    quotation.verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
  }

  function transferAssetFrom (address asset, address from, uint amount) public onlyInternal whenNotPaused {
    IERC20 token = IERC20(asset);
    token.safeTransferFrom(from, address(this), amount);
  }

  function transferAssetToSwapOperator (address asset, uint amount) public onlySwapOperator nonReentrant whenNotPaused {

    if (asset == ETH) {
      (bool ok, /* data */) = swapOperator.call.value(amount)("");
      require(ok, "Pool: Eth transfer failed");
      return;
    }

    IERC20 token = IERC20(asset);
    token.safeTransfer(swapOperator, amount);
  }

  function setAssetDataLastSwapTime(address asset, uint32 lastSwapTime) public onlySwapOperator whenNotPaused {
    assetData[asset].lastSwapTime = lastSwapTime;
  }

  /* token sale functions */

  /**
   * @dev (DEPRECATED, use sellTokens function instead) Allows selling of NXM for ether.
   * Seller first needs to give this contract allowance to
   * transfer/burn tokens in the NXMToken contract
   * @param  _amount Amount of NXM to sell
   * @return success returns true on successfull sale
   */
  function sellNXMTokens(uint _amount) public onlyMember whenNotPaused returns (bool success) {
    sellNXM(_amount, 0);
    return true;
  }

  /**
   * @dev (DEPRECATED, use calculateNXMForEth function instead) Returns the amount of wei a seller will get for selling NXM
   * @param amount Amount of NXM to sell
   * @return weiToPay Amount of wei the seller will get
   */
  function getWei(uint amount) external view returns (uint weiToPay) {
    return getEthForNXM(amount);
  }

  /**
   * @dev Buys NXM tokens with ETH.
   * @param  minTokensOut Minimum amount of tokens to be bought. Revert if boughtTokens falls below this number.
   * @return boughtTokens number of bought tokens.
   */
  function buyNXM(uint minTokensOut) public payable onlyMember whenNotPaused {

    uint ethIn = msg.value;
    require(ethIn > 0, "Pool: ethIn > 0");

    uint totalAssetValue = getPoolValueInEth().sub(ethIn);
    uint mcrEth = mcr.getMCR();
    uint mcrRatio = calculateMCRRatio(totalAssetValue, mcrEth);

    require(mcrRatio <= MAX_MCR_RATIO, "Pool: Cannot purchase if MCR% > 400%");
    uint tokensOut = calculateNXMForEth(ethIn, totalAssetValue, mcrEth);
    require(tokensOut >= minTokensOut, "Pool: tokensOut is less than minTokensOut");
    tokenController.mint(msg.sender, tokensOut);

    // evaluate the new MCR for the current asset value including the ETH paid in
    mcr.updateMCRInternal(totalAssetValue.add(ethIn), false);
    emit NXMBought(msg.sender, ethIn, tokensOut);
  }

  /**
   * @dev Sell NXM tokens and receive ETH.
   * @param tokenAmount Amount of tokens to sell.
   * @param  minEthOut Minimum amount of ETH to be received. Revert if ethOut falls below this number.
   * @return ethOut amount of ETH received in exchange for the tokens.
   */
  function sellNXM(uint tokenAmount, uint minEthOut) public onlyMember nonReentrant whenNotPaused {

    require(nxmToken.balanceOf(msg.sender) >= tokenAmount, "Pool: Not enough balance");
    require(nxmToken.isLockedForMV(msg.sender) <= now, "Pool: NXM tokens are locked for voting");

    uint currentTotalAssetValue = getPoolValueInEth();
    uint mcrEth = mcr.getMCR();
    uint ethOut = calculateEthForNXM(tokenAmount, currentTotalAssetValue, mcrEth);
    require(currentTotalAssetValue.sub(ethOut) >= mcrEth, "Pool: MCR% cannot fall below 100%");
    require(ethOut >= minEthOut, "Pool: ethOut < minEthOut");

    tokenController.burnFrom(msg.sender, tokenAmount);
    (bool ok, /* data */) = msg.sender.call.value(ethOut)("");
    require(ok, "Pool: Sell transfer failed");

    // evaluate the new MCR for the current asset value excluding the paid out ETH
    mcr.updateMCRInternal(currentTotalAssetValue.sub(ethOut), false);
    emit NXMSold(msg.sender, tokenAmount, ethOut);
  }

  /**
   * @dev Get value in tokens for an ethAmount purchase.
   * @param ethAmount amount of ETH used for buying.
   * @return tokenValue tokens obtained by buying worth of ethAmount
   */
  function getNXMForEth(
    uint ethAmount
  ) public view returns (uint) {
    uint totalAssetValue = getPoolValueInEth();
    uint mcrEth = mcr.getMCR();
    return calculateNXMForEth(ethAmount, totalAssetValue, mcrEth);
  }

  function calculateNXMForEth(
    uint ethAmount,
    uint currentTotalAssetValue,
    uint mcrEth
  ) public pure returns (uint) {

    require(
      ethAmount <= mcrEth.mul(MAX_BUY_SELL_MCR_ETH_FRACTION).div(10 ** MCR_RATIO_DECIMALS),
      "Pool: Purchases worth higher than 5% of MCReth are not allowed"
    );

    /*
      The price formula is:
      P(V) = A + MCReth / C *  MCR% ^ 4
      where MCR% = V / MCReth
      P(V) = A + 1 / (C * MCReth ^ 3) *  V ^ 4

      To compute the number of tokens issued we can integrate with respect to V the following:
        ΔT = ΔV / P(V)
        which assumes that for an infinitesimally small change in locked value V price is constant and we
        get an infinitesimally change in token supply ΔT.
      This is not computable on-chain, below we use an approximation that works well assuming
       * MCR% stays within [100%, 400%]
       * ethAmount <= 5% * MCReth

      Use a simplified formula excluding the constant A price offset to compute the amount of tokens to be minted.
      AdjustedP(V) = 1 / (C * MCReth ^ 3) *  V ^ 4
      AdjustedP(V) = 1 / (C * MCReth ^ 3) *  V ^ 4

      For a very small variation in tokens ΔT, we have,  ΔT = ΔV / P(V), to get total T we integrate with respect to V.
      adjustedTokenAmount = ∫ (dV / AdjustedP(V)) from V0 (currentTotalAssetValue) to V1 (nextTotalAssetValue)
      adjustedTokenAmount = ∫ ((C * MCReth ^ 3) / V ^ 4 * dV) from V0 to V1
      Evaluating the above using the antiderivative of the function we get:
      adjustedTokenAmount = - MCReth ^ 3 * C / (3 * V1 ^3) + MCReth * C /(3 * V0 ^ 3)
    */

    if (currentTotalAssetValue == 0 || mcrEth.div(currentTotalAssetValue) > 1e12) {
      /*
       If the currentTotalAssetValue = 0, adjustedTokenPrice approaches 0. Therefore we can assume the price is A.
       If currentTotalAssetValue is far smaller than mcrEth, MCR% approaches 0, let the price be A (baseline price).
       This avoids overflow in the calculateIntegralAtPoint computation.
       This approximation is safe from arbitrage since at MCR% < 100% no sells are possible.
      */
      uint tokenPrice = CONSTANT_A;
      return ethAmount.mul(1e18).div(tokenPrice);
    }

    // MCReth * C /(3 * V0 ^ 3)
    uint point0 = calculateIntegralAtPoint(currentTotalAssetValue, mcrEth);
    // MCReth * C / (3 * V1 ^3)
    uint nextTotalAssetValue = currentTotalAssetValue.add(ethAmount);
    uint point1 = calculateIntegralAtPoint(nextTotalAssetValue, mcrEth);
    uint adjustedTokenAmount = point0.sub(point1);
    /*
      Compute a preliminary adjustedTokenPrice for the minted tokens based on the adjustedTokenAmount above,
      and to that add the A constant (the price offset previously removed in the adjusted Price formula)
      to obtain the finalPrice and ultimately the tokenValue based on the finalPrice.

      adjustedPrice = ethAmount / adjustedTokenAmount
      finalPrice = adjustedPrice + A
      tokenValue = ethAmount  / finalPrice
    */
    // ethAmount is multiplied by 1e18 to cancel out the multiplication factor of 1e18 of the adjustedTokenAmount
    uint adjustedTokenPrice = ethAmount.mul(1e18).div(adjustedTokenAmount);
    uint tokenPrice = adjustedTokenPrice.add(CONSTANT_A);

    return ethAmount.mul(1e18).div(tokenPrice);
  }

  /**
   * @dev integral(V) =  MCReth ^ 3 * C / (3 * V ^ 3) * 1e18
   * computation result is multiplied by 1e18 to allow for a precision of 18 decimals.
   * NOTE: omits the minus sign of the correct integral to use a uint result type for simplicity
   * WARNING: this low-level function should be called from a contract which checks that
   * mcrEth / assetValue < 1e17 (no overflow) and assetValue != 0
   */
  function calculateIntegralAtPoint(
    uint assetValue,
    uint mcrEth
  ) internal pure returns (uint) {

    return CONSTANT_C
      .mul(1e18)
      .div(3)
      .mul(mcrEth).div(assetValue)
      .mul(mcrEth).div(assetValue)
      .mul(mcrEth).div(assetValue);
  }

  function getEthForNXM(uint nxmAmount) public view returns (uint ethAmount) {
    uint currentTotalAssetValue = getPoolValueInEth();
    uint mcrEth = mcr.getMCR();
    return calculateEthForNXM(nxmAmount, currentTotalAssetValue, mcrEth);
  }

  /**
   * @dev Computes token sell value for a tokenAmount in ETH with a sell spread of 2.5%.
   * for values in ETH of the sale <= 1% * MCReth the sell spread is very close to the exact value of 2.5%.
   * for values higher than that sell spread may exceed 2.5%
   * (The higher amount being sold at any given time the higher the spread)
   */
  function calculateEthForNXM(
    uint nxmAmount,
    uint currentTotalAssetValue,
    uint mcrEth
  ) public pure returns (uint) {

    // Step 1. Calculate spot price at current values and amount of ETH if tokens are sold at that price
    uint spotPrice0 = calculateTokenSpotPrice(currentTotalAssetValue, mcrEth);
    uint spotEthAmount = nxmAmount.mul(spotPrice0).div(1e18);

    //  Step 2. Calculate spot price using V = currentTotalAssetValue - spotEthAmount from step 1
    uint totalValuePostSpotPriceSell = currentTotalAssetValue.sub(spotEthAmount);
    uint spotPrice1 = calculateTokenSpotPrice(totalValuePostSpotPriceSell, mcrEth);

    // Step 3. Min [average[Price(0), Price(1)] x ( 1 - Sell Spread), Price(1) ]
    // Sell Spread = 2.5%
    uint averagePriceWithSpread = spotPrice0.add(spotPrice1).div(2).mul(975).div(1000);
    uint finalPrice = averagePriceWithSpread < spotPrice1 ? averagePriceWithSpread : spotPrice1;
    uint ethAmount = finalPrice.mul(nxmAmount).div(1e18);

    require(
      ethAmount <= mcrEth.mul(MAX_BUY_SELL_MCR_ETH_FRACTION).div(10 ** MCR_RATIO_DECIMALS),
      "Pool: Sales worth more than 5% of MCReth are not allowed"
    );

    return ethAmount;
  }

  function calculateMCRRatio(uint totalAssetValue, uint mcrEth) public pure returns (uint) {
    return totalAssetValue.mul(10 ** MCR_RATIO_DECIMALS).div(mcrEth);
  }

  /**
  * @dev Calculates token price in ETH 1 NXM token. TokenPrice = A + (MCReth / C) * MCR%^4
  */
  function calculateTokenSpotPrice(uint totalAssetValue, uint mcrEth) public pure returns (uint tokenPrice) {

    uint mcrRatio = calculateMCRRatio(totalAssetValue, mcrEth);
    uint precisionDecimals = 10 ** TOKEN_EXPONENT.mul(MCR_RATIO_DECIMALS);

    return mcrEth
      .mul(mcrRatio ** TOKEN_EXPONENT)
      .div(CONSTANT_C)
      .div(precisionDecimals)
      .add(CONSTANT_A);
  }

  /**
   * @dev Returns the NXM price in a given asset
   * @param asset Asset name.
   */
  function getTokenPrice(address asset) public view returns (uint tokenPrice) {

    uint totalAssetValue = getPoolValueInEth();
    uint mcrEth = mcr.getMCR();
    uint tokenSpotPriceEth = calculateTokenSpotPrice(totalAssetValue, mcrEth);

    return priceFeedOracle.getAssetForEth(asset, tokenSpotPriceEth);
  }

  function getMCRRatio() public view returns (uint) {
    uint totalAssetValue = getPoolValueInEth();
    uint mcrEth = mcr.getMCR();
    return calculateMCRRatio(totalAssetValue, mcrEth);
  }

  function updateUintParameters(bytes8 code, uint value) external onlyGovernance {

    if (code == "MIN_ETH") {
      minPoolEth = value;
      return;
    }

    revert("Pool: unknown parameter");
  }

  function updateAddressParameters(bytes8 code, address value) external onlyGovernance {

    if (code == "SWP_OP") {
      swapOperator = value;
      return;
    }

    if (code == "PRC_FEED") {
      priceFeedOracle = PriceFeedOracle(value);
      return;
    }

    revert("Pool: unknown parameter");
  }
}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

//Claims Reward Contract contains the functions for calculating number of tokens
// that will get rewarded, unlocked or burned depending upon the status of claim.

pragma solidity ^0.5.0;

import "../../interfaces/IPooledStaking.sol";
import "../capital/Pool.sol";
import "../cover/QuotationData.sol";
import "../governance/Governance.sol";
import "../token/TokenData.sol";
import "../token/TokenFunctions.sol";
import "./Claims.sol";
import "./ClaimsData.sol";
import "../capital/MCR.sol";

contract ClaimsReward is Iupgradable {
  using SafeMath for uint;

  NXMToken internal tk;
  TokenController internal tc;
  TokenData internal td;
  QuotationData internal qd;
  Claims internal c1;
  ClaimsData internal cd;
  Pool internal pool;
  Governance internal gv;
  IPooledStaking internal pooledStaking;
  MemberRoles internal memberRoles;
  MCR public mcr;

  // assigned in constructor
  address public DAI;

  // constants
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint private constant DECIMAL1E18 = uint(10) ** 18;

  constructor (address masterAddress, address _daiAddress) public {
    changeMasterAddress(masterAddress);
    DAI = _daiAddress;
  }

  function changeDependentContractAddress() public onlyInternal {
    c1 = Claims(ms.getLatestAddress("CL"));
    cd = ClaimsData(ms.getLatestAddress("CD"));
    tk = NXMToken(ms.tokenAddress());
    tc = TokenController(ms.getLatestAddress("TC"));
    td = TokenData(ms.getLatestAddress("TD"));
    qd = QuotationData(ms.getLatestAddress("QD"));
    gv = Governance(ms.getLatestAddress("GV"));
    pooledStaking = IPooledStaking(ms.getLatestAddress("PS"));
    memberRoles = MemberRoles(ms.getLatestAddress("MR"));
    pool = Pool(ms.getLatestAddress("P1"));
    mcr = MCR(ms.getLatestAddress("MC"));
  }

  /// @dev Decides the next course of action for a given claim.
  function changeClaimStatus(uint claimid) public checkPause onlyInternal {

    (, uint coverid) = cd.getClaimCoverId(claimid);
    (, uint status) = cd.getClaimStatusNumber(claimid);

    // when current status is "Pending-Claim Assessor Vote"
    if (status == 0) {
      _changeClaimStatusCA(claimid, coverid, status);
    } else if (status >= 1 && status <= 5) {
      _changeClaimStatusMV(claimid, coverid, status);
    } else if (status == 12) {// when current status is "Claim Accepted Payout Pending"

      bool payoutSucceeded = attemptClaimPayout(coverid);

      if (payoutSucceeded) {
        c1.setClaimStatus(claimid, 14);
      } else {
        c1.setClaimStatus(claimid, 12);
      }
    }
  }

  function getCurrencyAssetAddress(bytes4 currency) public view returns (address) {

    if (currency == "ETH") {
      return ETH;
    }

    if (currency == "DAI") {
      return DAI;
    }

    revert("ClaimsReward: unknown asset");
  }

  function attemptClaimPayout(uint coverId) internal returns (bool success) {

    uint sumAssured = qd.getCoverSumAssured(coverId);
    // TODO: when adding new cover currencies, fetch the correct decimals for this multiplication
    uint sumAssuredWei = sumAssured.mul(1e18);

    // get asset address
    bytes4 coverCurrency = qd.getCurrencyOfCover(coverId);
    address asset = getCurrencyAssetAddress(coverCurrency);

    // get payout address
    address payable coverHolder = qd.getCoverMemberAddress(coverId);
    address payable payoutAddress = memberRoles.getClaimPayoutAddress(coverHolder);

    // execute the payout
    bool payoutSucceeded = pool.sendClaimPayout(asset, payoutAddress, sumAssuredWei);

    if (payoutSucceeded) {

      // burn staked tokens
      (, address scAddress) = qd.getscAddressOfCover(coverId);
      uint tokenPrice = pool.getTokenPrice(asset);

      // note: for new assets "18" needs to be replaced with target asset decimals
      uint burnNXMAmount = sumAssuredWei.mul(1e18).div(tokenPrice);
      pooledStaking.pushBurn(scAddress, burnNXMAmount);

      // adjust total sum assured
      (, address coverContract) = qd.getscAddressOfCover(coverId);
      qd.subFromTotalSumAssured(coverCurrency, sumAssured);
      qd.subFromTotalSumAssuredSC(coverContract, coverCurrency, sumAssured);

      // update MCR since total sum assured and MCR% change
      mcr.updateMCRInternal(pool.getPoolValueInEth(), true);
      return true;
    }

    return false;
  }

  /// @dev Amount of tokens to be rewarded to a user for a particular vote id.
  /// @param check 1 -> CA vote, else member vote
  /// @param voteid vote id for which reward has to be Calculated
  /// @param flag if 1 calculate even if claimed,else don't calculate if already claimed
  /// @return tokenCalculated reward to be given for vote id
  /// @return lastClaimedCheck true if final verdict is still pending for that voteid
  /// @return tokens number of tokens locked under that voteid
  /// @return perc percentage of reward to be given.
  function getRewardToBeGiven(
    uint check,
    uint voteid,
    uint flag
  )
  public
  view
  returns (
    uint tokenCalculated,
    bool lastClaimedCheck,
    uint tokens,
    uint perc
  )

  {
    uint claimId;
    int8 verdict;
    bool claimed;
    uint tokensToBeDist;
    uint totalTokens;
    (tokens, claimId, verdict, claimed) = cd.getVoteDetails(voteid);
    lastClaimedCheck = false;
    int8 claimVerdict = cd.getFinalVerdict(claimId);
    if (claimVerdict == 0) {
      lastClaimedCheck = true;
    }

    if (claimVerdict == verdict && (claimed == false || flag == 1)) {

      if (check == 1) {
        (perc, , tokensToBeDist) = cd.getClaimRewardDetail(claimId);
      } else {
        (, perc, tokensToBeDist) = cd.getClaimRewardDetail(claimId);
      }

      if (perc > 0) {
        if (check == 1) {
          if (verdict == 1) {
            (, totalTokens,) = cd.getClaimsTokenCA(claimId);
          } else {
            (,, totalTokens) = cd.getClaimsTokenCA(claimId);
          }
        } else {
          if (verdict == 1) {
            (, totalTokens,) = cd.getClaimsTokenMV(claimId);
          } else {
            (,, totalTokens) = cd.getClaimsTokenMV(claimId);
          }
        }
        tokenCalculated = (perc.mul(tokens).mul(tokensToBeDist)).div(totalTokens.mul(100));


      }
    }
  }

  /// @dev Transfers all tokens held by contract to a new contract in case of upgrade.
  function upgrade(address _newAdd) public onlyInternal {
    uint amount = tk.balanceOf(address(this));
    if (amount > 0) {
      require(tk.transfer(_newAdd, amount));
    }

  }

  /// @dev Total reward in token due for claim by a user.
  /// @return total total number of tokens
  function getRewardToBeDistributedByUser(address _add) public view returns (uint total) {
    uint lengthVote = cd.getVoteAddressCALength(_add);
    uint lastIndexCA;
    uint lastIndexMV;
    uint tokenForVoteId;
    uint voteId;
    (lastIndexCA, lastIndexMV) = cd.getRewardDistributedIndex(_add);

    for (uint i = lastIndexCA; i < lengthVote; i++) {
      voteId = cd.getVoteAddressCA(_add, i);
      (tokenForVoteId,,,) = getRewardToBeGiven(1, voteId, 0);
      total = total.add(tokenForVoteId);
    }

    lengthVote = cd.getVoteAddressMemberLength(_add);

    for (uint j = lastIndexMV; j < lengthVote; j++) {
      voteId = cd.getVoteAddressMember(_add, j);
      (tokenForVoteId,,,) = getRewardToBeGiven(0, voteId, 0);
      total = total.add(tokenForVoteId);
    }
    return (total);
  }

  /// @dev Gets reward amount and claiming status for a given claim id.
  /// @return reward amount of tokens to user.
  /// @return claimed true if already claimed false if yet to be claimed.
  function getRewardAndClaimedStatus(uint check, uint claimId) public view returns (uint reward, bool claimed) {
    uint voteId;
    uint claimid;
    uint lengthVote;

    if (check == 1) {
      lengthVote = cd.getVoteAddressCALength(msg.sender);
      for (uint i = 0; i < lengthVote; i++) {
        voteId = cd.getVoteAddressCA(msg.sender, i);
        (, claimid, , claimed) = cd.getVoteDetails(voteId);
        if (claimid == claimId) {break;}
      }
    } else {
      lengthVote = cd.getVoteAddressMemberLength(msg.sender);
      for (uint j = 0; j < lengthVote; j++) {
        voteId = cd.getVoteAddressMember(msg.sender, j);
        (, claimid, , claimed) = cd.getVoteDetails(voteId);
        if (claimid == claimId) {break;}
      }
    }
    (reward,,,) = getRewardToBeGiven(check, voteId, 1);

  }

  /**
   * @dev Function used to claim all pending rewards : Claims Assessment + Risk Assessment + Governance
   * Claim assesment, Risk assesment, Governance rewards
   */
  function claimAllPendingReward(uint records) public isMemberAndcheckPause {
    _claimRewardToBeDistributed(records);
    pooledStaking.withdrawReward(msg.sender);
    uint governanceRewards = gv.claimReward(msg.sender, records);
    if (governanceRewards > 0) {
      require(tk.transfer(msg.sender, governanceRewards));
    }
  }

  /**
   * @dev Function used to get pending rewards of a particular user address.
   * @param _add user address.
   * @return total reward amount of the user
   */
  function getAllPendingRewardOfUser(address _add) public view returns (uint) {
    uint caReward = getRewardToBeDistributedByUser(_add);
    uint pooledStakingReward = pooledStaking.stakerReward(_add);
    uint governanceReward = gv.getPendingReward(_add);
    return caReward.add(pooledStakingReward).add(governanceReward);
  }

  /// @dev Rewards/Punishes users who  participated in Claims assessment.
  //    Unlocking and burning of the tokens will also depend upon the status of claim.
  /// @param claimid Claim Id.
  function _rewardAgainstClaim(uint claimid, uint coverid, uint status) internal {

    uint premiumNXM = qd.getCoverPremiumNXM(coverid);
    uint distributableTokens = premiumNXM.mul(cd.claimRewardPerc()).div(100); // 20% of premium

    uint percCA;
    uint percMV;

    (percCA, percMV) = cd.getRewardStatus(status);
    cd.setClaimRewardDetail(claimid, percCA, percMV, distributableTokens);

    if (percCA > 0 || percMV > 0) {
      tc.mint(address(this), distributableTokens);
    }

    // denied
    if (status == 6 || status == 9 || status == 11) {

      cd.changeFinalVerdict(claimid, -1);
      tc.markCoverClaimClosed(coverid, false);
      _burnCoverNoteDeposit(coverid);

    // accepted
    } else if (status == 7 || status == 8 || status == 10) {

      cd.changeFinalVerdict(claimid, 1);
      tc.markCoverClaimClosed(coverid, true);
      _unlockCoverNote(coverid);

      bool payoutSucceeded = attemptClaimPayout(coverid);

      // 12 = payout pending, 14 = payout succeeded
      uint nextStatus = payoutSucceeded ? 14 : 12;
      c1.setClaimStatus(claimid, nextStatus);
    }
  }

  function _burnCoverNoteDeposit(uint coverId) internal {

    address _of = qd.getCoverMemberAddress(coverId);
    bytes32 reason = keccak256(abi.encodePacked("CN", _of, coverId));
    uint lockedAmount = tc.tokensLocked(_of, reason);

    (uint amount,) = td.depositedCN(coverId);
    amount = amount.div(2);

    // limit burn amount to actual amount locked
    uint burnAmount = lockedAmount < amount ? lockedAmount : amount;

    if (burnAmount != 0) {
      tc.burnLockedTokens(_of, reason, amount);
    }
  }

  function _unlockCoverNote(uint coverId) internal {

    address coverHolder = qd.getCoverMemberAddress(coverId);
    bytes32 reason = keccak256(abi.encodePacked("CN", coverHolder, coverId));
    uint lockedCN = tc.tokensLocked(coverHolder, reason);

    if (lockedCN != 0) {
      tc.releaseLockedTokens(coverHolder, reason, lockedCN);
    }
  }

  /// @dev Computes the result of Claim Assessors Voting for a given claim id.
  function _changeClaimStatusCA(uint claimid, uint coverid, uint status) internal {
    // Check if voting should be closed or not
    if (c1.checkVoteClosing(claimid) == 1) {
      uint caTokens = c1.getCATokens(claimid, 0); // converted in cover currency.
      uint accept;
      uint deny;
      uint acceptAndDeny;
      bool rewardOrPunish;
      uint sumAssured;
      (, accept) = cd.getClaimVote(claimid, 1);
      (, deny) = cd.getClaimVote(claimid, - 1);
      acceptAndDeny = accept.add(deny);
      accept = accept.mul(100);
      deny = deny.mul(100);

      if (caTokens == 0) {
        status = 3;
      } else {
        sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
        // Min threshold reached tokens used for voting > 5* sum assured
        if (caTokens > sumAssured.mul(5)) {

          if (accept.div(acceptAndDeny) > 70) {
            status = 7;
            qd.changeCoverStatusNo(coverid, uint8(QuotationData.CoverStatus.ClaimAccepted));
            rewardOrPunish = true;
          } else if (deny.div(acceptAndDeny) > 70) {
            status = 6;
            qd.changeCoverStatusNo(coverid, uint8(QuotationData.CoverStatus.ClaimDenied));
            rewardOrPunish = true;
          } else if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
            status = 4;
          } else {
            status = 5;
          }

        } else {

          if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
            status = 2;
          } else {
            status = 3;
          }
        }
      }

      c1.setClaimStatus(claimid, status);

      if (rewardOrPunish) {
        _rewardAgainstClaim(claimid, coverid, status);
      }
    }
  }

  /// @dev Computes the result of Member Voting for a given claim id.
  function _changeClaimStatusMV(uint claimid, uint coverid, uint status) internal {

    // Check if voting should be closed or not
    if (c1.checkVoteClosing(claimid) == 1) {
      uint8 coverStatus;
      uint statusOrig = status;
      uint mvTokens = c1.getCATokens(claimid, 1); // converted in cover currency.

      // If tokens used for acceptance >50%, claim is accepted
      uint sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
      uint thresholdUnreached = 0;
      // Minimum threshold for member voting is reached only when
      // value of tokens used for voting > 5* sum assured of claim id
      if (mvTokens < sumAssured.mul(5)) {
        thresholdUnreached = 1;
      }

      uint accept;
      (, accept) = cd.getClaimMVote(claimid, 1);
      uint deny;
      (, deny) = cd.getClaimMVote(claimid, - 1);

      if (accept.add(deny) > 0) {
        if (accept.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
        statusOrig <= 5 && thresholdUnreached == 0) {
          status = 8;
          coverStatus = uint8(QuotationData.CoverStatus.ClaimAccepted);
        } else if (deny.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
        statusOrig <= 5 && thresholdUnreached == 0) {
          status = 9;
          coverStatus = uint8(QuotationData.CoverStatus.ClaimDenied);
        }
      }

      if (thresholdUnreached == 1 && (statusOrig == 2 || statusOrig == 4)) {
        status = 10;
        coverStatus = uint8(QuotationData.CoverStatus.ClaimAccepted);
      } else if (thresholdUnreached == 1 && (statusOrig == 5 || statusOrig == 3 || statusOrig == 1)) {
        status = 11;
        coverStatus = uint8(QuotationData.CoverStatus.ClaimDenied);
      }

      c1.setClaimStatus(claimid, status);
      qd.changeCoverStatusNo(coverid, uint8(coverStatus));
      // Reward/Punish Claim Assessors and Members who participated in Claims assessment
      _rewardAgainstClaim(claimid, coverid, status);
    }
  }

  /// @dev Allows a user to claim all pending  Claims assessment rewards.
  function _claimRewardToBeDistributed(uint _records) internal {
    uint lengthVote = cd.getVoteAddressCALength(msg.sender);
    uint voteid;
    uint lastIndex;
    (lastIndex,) = cd.getRewardDistributedIndex(msg.sender);
    uint total = 0;
    uint tokenForVoteId = 0;
    bool lastClaimedCheck;
    uint _days = td.lockCADays();
    bool claimed;
    uint counter = 0;
    uint claimId;
    uint perc;
    uint i;
    uint lastClaimed = lengthVote;

    for (i = lastIndex; i < lengthVote && counter < _records; i++) {
      voteid = cd.getVoteAddressCA(msg.sender, i);
      (tokenForVoteId, lastClaimedCheck, , perc) = getRewardToBeGiven(1, voteid, 0);
      if (lastClaimed == lengthVote && lastClaimedCheck == true) {
        lastClaimed = i;
      }
      (, claimId, , claimed) = cd.getVoteDetails(voteid);

      if (perc > 0 && !claimed) {
        counter++;
        cd.setRewardClaimed(voteid, true);
      } else if (perc == 0 && cd.getFinalVerdict(claimId) != 0 && !claimed) {
        (perc,,) = cd.getClaimRewardDetail(claimId);
        if (perc == 0) {
          counter++;
        }
        cd.setRewardClaimed(voteid, true);
      }
      if (tokenForVoteId > 0) {
        total = tokenForVoteId.add(total);
      }
    }
    if (lastClaimed == lengthVote) {
      cd.setRewardDistributedIndexCA(msg.sender, i);
    }
    else {
      cd.setRewardDistributedIndexCA(msg.sender, lastClaimed);
    }
    lengthVote = cd.getVoteAddressMemberLength(msg.sender);
    lastClaimed = lengthVote;
    _days = _days.mul(counter);
    if (tc.tokensLockedAtTime(msg.sender, "CLA", now) > 0) {
      tc.reduceLock(msg.sender, "CLA", _days);
    }
    (, lastIndex) = cd.getRewardDistributedIndex(msg.sender);
    lastClaimed = lengthVote;
    counter = 0;
    for (i = lastIndex; i < lengthVote && counter < _records; i++) {
      voteid = cd.getVoteAddressMember(msg.sender, i);
      (tokenForVoteId, lastClaimedCheck,,) = getRewardToBeGiven(0, voteid, 0);
      if (lastClaimed == lengthVote && lastClaimedCheck == true) {
        lastClaimed = i;
      }
      (, claimId, , claimed) = cd.getVoteDetails(voteid);
      if (claimed == false && cd.getFinalVerdict(claimId) != 0) {
        cd.setRewardClaimed(voteid, true);
        counter++;
      }
      if (tokenForVoteId > 0) {
        total = tokenForVoteId.add(total);
      }
    }
    if (total > 0) {
      require(tk.transfer(msg.sender, total));
    }
    if (lastClaimed == lengthVote) {
      cd.setRewardDistributedIndexMV(msg.sender, i);
    }
    else {
      cd.setRewardDistributedIndexMV(msg.sender, lastClaimed);
    }
  }

  /**
   * @dev Function used to claim the commission earned by the staker.
   */
  function _claimStakeCommission(uint _records, address _user) external onlyInternal {
    uint total = 0;
    uint len = td.getStakerStakedContractLength(_user);
    uint lastCompletedStakeCommission = td.lastCompletedStakeCommission(_user);
    uint commissionEarned;
    uint commissionRedeemed;
    uint maxCommission;
    uint lastCommisionRedeemed = len;
    uint counter;
    uint i;

    for (i = lastCompletedStakeCommission; i < len && counter < _records; i++) {
      commissionRedeemed = td.getStakerRedeemedStakeCommission(_user, i);
      commissionEarned = td.getStakerEarnedStakeCommission(_user, i);
      maxCommission = td.getStakerInitialStakedAmountOnContract(
        _user, i).mul(td.stakerMaxCommissionPer()).div(100);
      if (lastCommisionRedeemed == len && maxCommission != commissionEarned)
        lastCommisionRedeemed = i;
      td.pushRedeemedStakeCommissions(_user, i, commissionEarned.sub(commissionRedeemed));
      total = total.add(commissionEarned.sub(commissionRedeemed));
      counter++;
    }
    if (lastCommisionRedeemed == len) {
      td.setLastCompletedStakeCommissionIndex(_user, i);
    } else {
      td.setLastCompletedStakeCommissionIndex(_user, lastCommisionRedeemed);
    }

    if (total > 0)
      require(tk.transfer(_user, total)); // solhint-disable-line
  }

}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "./external/OZIERC20.sol";
import "./external/OZSafeMath.sol";

contract NXMToken is OZIERC20 {
  using OZSafeMath for uint256;

  event WhiteListed(address indexed member);

  event BlackListed(address indexed member);

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowed;

  mapping(address => bool) public whiteListed;

  mapping(address => uint) public isLockedForMV;

  uint256 private _totalSupply;

  string public name = "NXM";
  string public symbol = "NXM";
  uint8 public decimals = 18;
  address public operator;

  modifier canTransfer(address _to) {
    require(whiteListed[_to]);
    _;
  }

  modifier onlyOperator() {
    if (operator != address(0))
      require(msg.sender == operator);
    _;
  }

  constructor(address _founderAddress, uint _initialSupply) public {
    _mint(_founderAddress, _initialSupply);
  }

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
  * @dev Function to check the amount of tokens that an owner allowed to a spender.
  * @param owner address The address which owns the funds.
  * @param spender address The address which will spend the funds.
  * @return A uint256 specifying the amount of tokens still available for the spender.
  */
  function allowance(
    address owner,
    address spender
  )
  public
  view
  returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
  * Beware that changing an allowance with this method brings the risk that someone may use both the old
  * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
  * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
  * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
  * @param spender The address which will spend the funds.
  * @param value The amount of tokens to be spent.
  */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
  * @dev Increase the amount of tokens that an owner allowed to a spender.
  * approve should be called when allowed_[_spender] == 0. To increment
  * allowed value is better to use this function to avoid 2 calls (and wait until
  * the first transaction is mined)
  * From MonolithDAO Token.sol
  * @param spender The address which will spend the funds.
  * @param addedValue The amount of tokens to increase the allowance by.
  */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
  public
  returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Decrease the amount of tokens that an owner allowed to a spender.
  * approve should be called when allowed_[_spender] == 0. To decrement
  * allowed value is better to use this function to avoid 2 calls (and wait until
  * the first transaction is mined)
  * From MonolithDAO Token.sol
  * @param spender The address which will spend the funds.
  * @param subtractedValue The amount of tokens to decrease the allowance by.
  */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
  public
  returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Adds a user to whitelist
  * @param _member address to add to whitelist
  */
  function addToWhiteList(address _member) public onlyOperator returns (bool) {
    whiteListed[_member] = true;
    emit WhiteListed(_member);
    return true;
  }

  /**
  * @dev removes a user from whitelist
  * @param _member address to remove from whitelist
  */
  function removeFromWhiteList(address _member) public onlyOperator returns (bool) {
    whiteListed[_member] = false;
    emit BlackListed(_member);
    return true;
  }

  /**
  * @dev change operator address
  * @param _newOperator address of new operator
  */
  function changeOperator(address _newOperator) public onlyOperator returns (bool) {
    operator = _newOperator;
    return true;
  }

  /**
  * @dev burns an amount of the tokens of the message sender
  * account.
  * @param amount The amount that will be burnt.
  */
  function burn(uint256 amount) public returns (bool) {
    _burn(msg.sender, amount);
    return true;
  }

  /**
  * @dev Burns a specific amount of tokens from the target address and decrements allowance
  * @param from address The address which you want to send tokens from
  * @param value uint256 The amount of token to be burned
  */
  function burnFrom(address from, uint256 value) public returns (bool) {
    _burnFrom(from, value);
    return true;
  }

  /**
  * @dev function that mints an amount of the token and assigns it to
  * an account.
  * @param account The account that will receive the created tokens.
  * @param amount The amount that will be created.
  */
  function mint(address account, uint256 amount) public onlyOperator {
    _mint(account, amount);
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public canTransfer(to) returns (bool) {

    require(isLockedForMV[msg.sender] < now); // if not voted under governance
    require(value <= _balances[msg.sender]);
    _transfer(to, value);
    return true;
  }

  /**
  * @dev Transfer tokens to the operator from the specified address
  * @param from The address to transfer from.
  * @param value The amount to be transferred.
  */
  function operatorTransfer(address from, uint256 value) public onlyOperator returns (bool) {
    require(value <= _balances[from]);
    _transferFrom(from, operator, value);
    return true;
  }

  /**
  * @dev Transfer tokens from one address to another
  * @param from address The address which you want to send tokens from
  * @param to address The address which you want to transfer to
  * @param value uint256 the amount of tokens to be transferred
  */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
  public
  canTransfer(to)
  returns (bool)
  {
    require(isLockedForMV[from] < now); // if not voted under governance
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    _transferFrom(from, to, value);
    return true;
  }

  /**
   * @dev Lock the user's tokens
   * @param _of user's address.
   */
  function lockForMemberVote(address _of, uint _days) public onlyOperator {
    if (_days.add(now) > isLockedForMV[_of])
      isLockedForMV[_of] = _days.add(now);
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address to, uint256 value) internal {
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
  }

  /**
  * @dev Transfer tokens from one address to another
  * @param from address The address which you want to send tokens from
  * @param to address The address which you want to transfer to
  * @param value uint256 the amount of tokens to be transferred
  */
  function _transferFrom(
    address from,
    address to,
    uint256 value
  )
  internal
  {
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
  }

  /**
  * @dev Internal function that mints an amount of the token and assigns it to
  * an account. This encapsulates the modification of balances such that the
  * proper events are emitted.
  * @param account The account that will receive the created tokens.
  * @param amount The amount that will be created.
  */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0));
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
  * @dev Internal function that burns an amount of the token of a given
  * account.
  * @param account The account whose tokens will be burnt.
  * @param amount The amount that will be burnt.
  */
  function _burn(address account, uint256 amount) internal {
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
  * @dev Internal function that burns an amount of the token of a given
  * account, deducting from the sender's allowance for said account. Uses the
  * internal burn function.
  * @param account The account whose tokens will be burnt.
  * @param value The amount that will be burnt.
  */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../abstract/Iupgradable.sol";
import "../../interfaces/IPooledStaking.sol";
import "../claims/ClaimsData.sol";
import "./NXMToken.sol";
import "./external/LockHandler.sol";

contract TokenController is LockHandler, Iupgradable {
  using SafeMath for uint256;

  struct CoverInfo {
    uint16 claimCount;
    bool hasOpenClaim;
    bool hasAcceptedClaim;
    // note: still 224 bits available here, can be used later
  }

  NXMToken public token;
  IPooledStaking public pooledStaking;

  uint public minCALockTime;
  uint public claimSubmissionGracePeriod;

  // coverId => CoverInfo
  mapping(uint => CoverInfo) public coverInfo;

  event Locked(address indexed _of, bytes32 indexed _reason, uint256 _amount, uint256 _validity);

  event Unlocked(address indexed _of, bytes32 indexed _reason, uint256 _amount);

  event Burned(address indexed member, bytes32 lockedUnder, uint256 amount);

  modifier onlyGovernance {
    require(msg.sender == ms.getLatestAddress("GV"), "TokenController: Caller is not governance");
    _;
  }

  /**
  * @dev Just for interface
  */
  function changeDependentContractAddress() public {
    token = NXMToken(ms.tokenAddress());
    pooledStaking = IPooledStaking(ms.getLatestAddress("PS"));
  }

  function markCoverClaimOpen(uint coverId) external onlyInternal {

    CoverInfo storage info = coverInfo[coverId];

    uint16 claimCount;
    bool hasOpenClaim;
    bool hasAcceptedClaim;

    // reads all of them using a single SLOAD
    (claimCount, hasOpenClaim, hasAcceptedClaim) = (info.claimCount, info.hasOpenClaim, info.hasAcceptedClaim);

    // no safemath for uint16 but should be safe from
    // overflows as there're max 2 claims per cover
    claimCount = claimCount + 1;

    require(claimCount <= 2, "TokenController: Max claim count exceeded");
    require(hasOpenClaim == false, "TokenController: Cover already has an open claim");
    require(hasAcceptedClaim == false, "TokenController: Cover already has accepted claims");

    // should use a single SSTORE for both
    (info.claimCount, info.hasOpenClaim) = (claimCount, true);
  }

  /**
   * @param coverId cover id (careful, not claim id!)
   * @param isAccepted claim verdict
   */
  function markCoverClaimClosed(uint coverId, bool isAccepted) external onlyInternal {

    CoverInfo storage info = coverInfo[coverId];
    require(info.hasOpenClaim == true, "TokenController: Cover claim is not marked as open");

    // should use a single SSTORE for both
    (info.hasOpenClaim, info.hasAcceptedClaim) = (false, isAccepted);
  }

  /**
   * @dev to change the operator address
   * @param _newOperator is the new address of operator
   */
  function changeOperator(address _newOperator) public onlyInternal {
    token.changeOperator(_newOperator);
  }

  /**
   * @dev Proxies token transfer through this contract to allow staking when members are locked for voting
   * @param _from   Source address
   * @param _to     Destination address
   * @param _value  Amount to transfer
   */
  function operatorTransfer(address _from, address _to, uint _value) external onlyInternal returns (bool) {
    require(msg.sender == address(pooledStaking), "TokenController: Call is only allowed from PooledStaking address");
    token.operatorTransfer(_from, _value);
    token.transfer(_to, _value);
    return true;
  }

  /**
  * @dev Locks a specified amount of tokens,
  *    for CLA reason and for a specified time
  * @param _amount Number of tokens to be locked
  * @param _time Lock time in seconds
  */
  function lockClaimAssessmentTokens(uint256 _amount, uint256 _time) external checkPause {
    require(minCALockTime <= _time, "TokenController: Must lock for minimum time");
    require(_time <= 180 days, "TokenController: Tokens can be locked for 180 days maximum");
    // If tokens are already locked, then functions extendLock or
    // increaseClaimAssessmentLock should be used to make any changes
    _lock(msg.sender, "CLA", _amount, _time);
  }

  /**
  * @dev Locks a specified amount of tokens against an address,
  *    for a specified reason and time
  * @param _reason The reason to lock tokens
  * @param _amount Number of tokens to be locked
  * @param _time Lock time in seconds
  * @param _of address whose tokens are to be locked
  */
  function lockOf(address _of, bytes32 _reason, uint256 _amount, uint256 _time)
  public
  onlyInternal
  returns (bool)
  {
    // If tokens are already locked, then functions extendLock or
    // increaseLockAmount should be used to make any changes
    _lock(_of, _reason, _amount, _time);
    return true;
  }

  /**
  * @dev Mints and locks a specified amount of tokens against an address,
  *      for a CN reason and time
  * @param _of address whose tokens are to be locked
  * @param _reason The reason to lock tokens
  * @param _amount Number of tokens to be locked
  * @param _time Lock time in seconds
  */
  function mintCoverNote(
    address _of,
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  ) external onlyInternal {

    require(_tokensLocked(_of, _reason) == 0, "TokenController: An amount of tokens is already locked");
    require(_amount != 0, "TokenController: Amount shouldn't be zero");

    if (locked[_of][_reason].amount == 0) {
      lockReason[_of].push(_reason);
    }

    token.mint(address(this), _amount);

    uint256 lockedUntil = now.add(_time);
    locked[_of][_reason] = LockToken(_amount, lockedUntil, false);

    emit Locked(_of, _reason, _amount, lockedUntil);
  }

  /**
  * @dev Extends lock for reason CLA for a specified time
  * @param _time Lock extension time in seconds
  */
  function extendClaimAssessmentLock(uint256 _time) external checkPause {
    uint256 validity = getLockedTokensValidity(msg.sender, "CLA");
    require(validity.add(_time).sub(block.timestamp) <= 180 days, "TokenController: Tokens can be locked for 180 days maximum");
    _extendLock(msg.sender, "CLA", _time);
  }

  /**
  * @dev Extends lock for a specified reason and time
  * @param _reason The reason to lock tokens
  * @param _time Lock extension time in seconds
  */
  function extendLockOf(address _of, bytes32 _reason, uint256 _time)
  public
  onlyInternal
  returns (bool)
  {
    _extendLock(_of, _reason, _time);
    return true;
  }

  /**
  * @dev Increase number of tokens locked for a CLA reason
  * @param _amount Number of tokens to be increased
  */
  function increaseClaimAssessmentLock(uint256 _amount) external checkPause
  {
    require(_tokensLocked(msg.sender, "CLA") > 0, "TokenController: No tokens locked");
    token.operatorTransfer(msg.sender, _amount);

    locked[msg.sender]["CLA"].amount = locked[msg.sender]["CLA"].amount.add(_amount);
    emit Locked(msg.sender, "CLA", _amount, locked[msg.sender]["CLA"].validity);
  }

  /**
   * @dev burns tokens of an address
   * @param _of is the address to burn tokens of
   * @param amount is the amount to burn
   * @return the boolean status of the burning process
   */
  function burnFrom(address _of, uint amount) public onlyInternal returns (bool) {
    return token.burnFrom(_of, amount);
  }

  /**
  * @dev Burns locked tokens of a user
  * @param _of address whose tokens are to be burned
  * @param _reason lock reason for which tokens are to be burned
  * @param _amount amount of tokens to burn
  */
  function burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) public onlyInternal {
    _burnLockedTokens(_of, _reason, _amount);
  }

  /**
  * @dev reduce lock duration for a specified reason and time
  * @param _of The address whose tokens are locked
  * @param _reason The reason to lock tokens
  * @param _time Lock reduction time in seconds
  */
  function reduceLock(address _of, bytes32 _reason, uint256 _time) public onlyInternal {
    _reduceLock(_of, _reason, _time);
  }

  /**
  * @dev Released locked tokens of an address locked for a specific reason
  * @param _of address whose tokens are to be released from lock
  * @param _reason reason of the lock
  * @param _amount amount of tokens to release
  */
  function releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount)
  public
  onlyInternal
  {
    _releaseLockedTokens(_of, _reason, _amount);
  }

  /**
  * @dev Adds an address to whitelist maintained in the contract
  * @param _member address to add to whitelist
  */
  function addToWhitelist(address _member) public onlyInternal {
    token.addToWhiteList(_member);
  }

  /**
  * @dev Removes an address from the whitelist in the token
  * @param _member address to remove
  */
  function removeFromWhitelist(address _member) public onlyInternal {
    token.removeFromWhiteList(_member);
  }

  /**
  * @dev Mints new token for an address
  * @param _member address to reward the minted tokens
  * @param _amount number of tokens to mint
  */
  function mint(address _member, uint _amount) public onlyInternal {
    token.mint(_member, _amount);
  }

  /**
   * @dev Lock the user's tokens
   * @param _of user's address.
   */
  function lockForMemberVote(address _of, uint _days) public onlyInternal {
    token.lockForMemberVote(_of, _days);
  }

  /**
  * @dev Unlocks the withdrawable tokens against CLA of a specified address
  * @param _of Address of user, claiming back withdrawable tokens against CLA
  */
  function withdrawClaimAssessmentTokens(address _of) external checkPause {
    uint256 withdrawableTokens = _tokensUnlockable(_of, "CLA");
    if (withdrawableTokens > 0) {
      locked[_of]["CLA"].claimed = true;
      emit Unlocked(_of, "CLA", withdrawableTokens);
      token.transfer(_of, withdrawableTokens);
    }
  }

  /**
   * @dev Updates Uint Parameters of a code
   * @param code whose details we want to update
   * @param value value to set
   */
  function updateUintParameters(bytes8 code, uint value) external onlyGovernance {

    if (code == "MNCLT") {
      minCALockTime = value;
      return;
    }

    if (code == "GRACEPER") {
      claimSubmissionGracePeriod = value;
      return;
    }

    revert("TokenController: invalid param code");
  }

  function getLockReasons(address _of) external view returns (bytes32[] memory reasons) {
    return lockReason[_of];
  }

  /**
  * @dev Gets the validity of locked tokens of a specified address
  * @param _of The address to query the validity
  * @param reason reason for which tokens were locked
  */
  function getLockedTokensValidity(address _of, bytes32 reason) public view returns (uint256 validity) {
    validity = locked[_of][reason].validity;
  }

  /**
  * @dev Gets the unlockable tokens of a specified address
  * @param _of The address to query the the unlockable token count of
  */
  function getUnlockableTokens(address _of)
  public
  view
  returns (uint256 unlockableTokens)
  {
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      unlockableTokens = unlockableTokens.add(_tokensUnlockable(_of, lockReason[_of][i]));
    }
  }

  /**
  * @dev Returns tokens locked for a specified address for a
  *    specified reason
  *
  * @param _of The address whose tokens are locked
  * @param _reason The reason to query the lock tokens for
  */
  function tokensLocked(address _of, bytes32 _reason)
  public
  view
  returns (uint256 amount)
  {
    return _tokensLocked(_of, _reason);
  }

  /**
  * @dev Returns tokens locked and validity for a specified address and reason
  * @param _of The address whose tokens are locked
  * @param _reason The reason to query the lock tokens for
  */
  function tokensLockedWithValidity(address _of, bytes32 _reason)
  public
  view
  returns (uint256 amount, uint256 validity)
  {

    bool claimed = locked[_of][_reason].claimed;
    amount = locked[_of][_reason].amount;
    validity = locked[_of][_reason].validity;

    if (claimed) {
      amount = 0;
    }
  }

  /**
  * @dev Returns unlockable tokens for a specified address for a specified reason
  * @param _of The address to query the the unlockable token count of
  * @param _reason The reason to query the unlockable tokens for
  */
  function tokensUnlockable(address _of, bytes32 _reason)
  public
  view
  returns (uint256 amount)
  {
    return _tokensUnlockable(_of, _reason);
  }

  function totalSupply() public view returns (uint256)
  {
    return token.totalSupply();
  }

  /**
  * @dev Returns tokens locked for a specified address for a
  *    specified reason at a specific time
  *
  * @param _of The address whose tokens are locked
  * @param _reason The reason to query the lock tokens for
  * @param _time The timestamp to query the lock tokens for
  */
  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
  public
  view
  returns (uint256 amount)
  {
    return _tokensLockedAtTime(_of, _reason, _time);
  }

  /**
  * @dev Returns the total amount of tokens held by an address:
  *   transferable + locked + staked for pooled staking - pending burns.
  *   Used by Claims and Governance in member voting to calculate the user's vote weight.
  *
  * @param _of The address to query the total balance of
  * @param _of The address to query the total balance of
  */
  function totalBalanceOf(address _of) public view returns (uint256 amount) {

    amount = token.balanceOf(_of);

    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      amount = amount.add(_tokensLocked(_of, lockReason[_of][i]));
    }

    uint stakerReward = pooledStaking.stakerReward(_of);
    uint stakerDeposit = pooledStaking.stakerDeposit(_of);

    amount = amount.add(stakerDeposit).add(stakerReward);
  }

  /**
  * @dev Returns the total amount of locked and staked tokens.
  *      Used by MemberRoles to check eligibility for withdraw / switch membership.
  *      Includes tokens locked for claim assessment, tokens staked for risk assessment, and locked cover notes
  *      Does not take into account pending burns.
  * @param _of member whose locked tokens are to be calculate
  */
  function totalLockedBalance(address _of) public view returns (uint256 amount) {

    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      amount = amount.add(_tokensLocked(_of, lockReason[_of][i]));
    }

    amount = amount.add(pooledStaking.stakerDeposit(_of));
  }

  /**
  * @dev Locks a specified amount of tokens against an address,
  *    for a specified reason and time
  * @param _of address whose tokens are to be locked
  * @param _reason The reason to lock tokens
  * @param _amount Number of tokens to be locked
  * @param _time Lock time in seconds
  */
  function _lock(address _of, bytes32 _reason, uint256 _amount, uint256 _time) internal {
    require(_tokensLocked(_of, _reason) == 0, "TokenController: An amount of tokens is already locked");
    require(_amount != 0, "TokenController: Amount shouldn't be zero");

    if (locked[_of][_reason].amount == 0) {
      lockReason[_of].push(_reason);
    }

    token.operatorTransfer(_of, _amount);

    uint256 validUntil = now.add(_time);
    locked[_of][_reason] = LockToken(_amount, validUntil, false);
    emit Locked(_of, _reason, _amount, validUntil);
  }

  /**
  * @dev Returns tokens locked for a specified address for a
  *    specified reason
  *
  * @param _of The address whose tokens are locked
  * @param _reason The reason to query the lock tokens for
  */
  function _tokensLocked(address _of, bytes32 _reason)
  internal
  view
  returns (uint256 amount)
  {
    if (!locked[_of][_reason].claimed) {
      amount = locked[_of][_reason].amount;
    }
  }

  /**
  * @dev Returns tokens locked for a specified address for a
  *    specified reason at a specific time
  *
  * @param _of The address whose tokens are locked
  * @param _reason The reason to query the lock tokens for
  * @param _time The timestamp to query the lock tokens for
  */
  function _tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
  internal
  view
  returns (uint256 amount)
  {
    if (locked[_of][_reason].validity > _time) {
      amount = locked[_of][_reason].amount;
    }
  }

  /**
  * @dev Extends lock for a specified reason and time
  * @param _of The address whose tokens are locked
  * @param _reason The reason to lock tokens
  * @param _time Lock extension time in seconds
  */
  function _extendLock(address _of, bytes32 _reason, uint256 _time) internal {
    require(_tokensLocked(_of, _reason) > 0, "TokenController: No tokens locked");
    emit Unlocked(_of, _reason, locked[_of][_reason].amount);
    locked[_of][_reason].validity = locked[_of][_reason].validity.add(_time);
    emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
  }

  /**
  * @dev reduce lock duration for a specified reason and time
  * @param _of The address whose tokens are locked
  * @param _reason The reason to lock tokens
  * @param _time Lock reduction time in seconds
  */
  function _reduceLock(address _of, bytes32 _reason, uint256 _time) internal {
    require(_tokensLocked(_of, _reason) > 0, "TokenController: No tokens locked");
    emit Unlocked(_of, _reason, locked[_of][_reason].amount);
    locked[_of][_reason].validity = locked[_of][_reason].validity.sub(_time);
    emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
  }

  /**
  * @dev Returns unlockable tokens for a specified address for a specified reason
  * @param _of The address to query the the unlockable token count of
  * @param _reason The reason to query the unlockable tokens for
  */
  function _tokensUnlockable(address _of, bytes32 _reason) internal view returns (uint256 amount)
  {
    if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) {
      amount = locked[_of][_reason].amount;
    }
  }

  /**
  * @dev Burns locked tokens of a user
  * @param _of address whose tokens are to be burned
  * @param _reason lock reason for which tokens are to be burned
  * @param _amount amount of tokens to burn
  */
  function _burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) internal {
    uint256 amount = _tokensLocked(_of, _reason);
    require(amount >= _amount, "TokenController: Amount exceedes locked tokens amount");

    if (amount == _amount) {
      locked[_of][_reason].claimed = true;
    }

    locked[_of][_reason].amount = locked[_of][_reason].amount.sub(_amount);

    // lock reason removal is skipped here: needs to be done from offchain

    token.burn(_amount);
    emit Burned(_of, _reason, _amount);
  }

  /**
  * @dev Released locked tokens of an address locked for a specific reason
  * @param _of address whose tokens are to be released from lock
  * @param _reason reason of the lock
  * @param _amount amount of tokens to release
  */
  function _releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount) internal
  {
    uint256 amount = _tokensLocked(_of, _reason);
    require(amount >= _amount, "TokenController: Amount exceedes locked tokens amount");

    if (amount == _amount) {
      locked[_of][_reason].claimed = true;
    }

    locked[_of][_reason].amount = locked[_of][_reason].amount.sub(_amount);

    // lock reason removal is skipped here: needs to be done from offchain

    token.transfer(_of, _amount);
    emit Unlocked(_of, _reason, _amount);
  }

  function withdrawCoverNote(
    address _of,
    uint[] calldata _coverIds,
    uint[] calldata _indexes
  ) external onlyInternal {

    uint reasonCount = lockReason[_of].length;
    uint lastReasonIndex = reasonCount.sub(1, "TokenController: No locked cover notes found");
    uint totalAmount = 0;

    // The iteration is done from the last to first to prevent reason indexes from
    // changing due to the way we delete the items (copy last to current and pop last).
    // The provided indexes array must be ordered, otherwise reason index checks will fail.

    for (uint i = _coverIds.length; i > 0; i--) {

      bool hasOpenClaim = coverInfo[_coverIds[i - 1]].hasOpenClaim;
      require(hasOpenClaim == false, "TokenController: Cannot withdraw for cover with an open claim");

      // note: cover owner is implicitly checked using the reason hash
      bytes32 _reason = keccak256(abi.encodePacked("CN", _of, _coverIds[i - 1]));
      uint _reasonIndex = _indexes[i - 1];
      require(lockReason[_of][_reasonIndex] == _reason, "TokenController: Bad reason index");

      uint amount = locked[_of][_reason].amount;
      totalAmount = totalAmount.add(amount);
      delete locked[_of][_reason];

      if (lastReasonIndex != _reasonIndex) {
        lockReason[_of][_reasonIndex] = lockReason[_of][lastReasonIndex];
      }

      lockReason[_of].pop();
      emit Unlocked(_of, _reason, amount);

      if (lastReasonIndex > 0) {
        lastReasonIndex = lastReasonIndex.sub(1, "TokenController: Reason count mismatch");
      }
    }

    token.transfer(_of, totalAmount);
  }

  function removeEmptyReason(address _of, bytes32 _reason, uint _index) external {
    _removeEmptyReason(_of, _reason, _index);
  }

  function removeMultipleEmptyReasons(
    address[] calldata _members,
    bytes32[] calldata _reasons,
    uint[] calldata _indexes
  ) external {

    require(_members.length == _reasons.length, "TokenController: members and reasons array lengths differ");
    require(_reasons.length == _indexes.length, "TokenController: reasons and indexes array lengths differ");

    for (uint i = _members.length; i > 0; i--) {
      uint idx = i - 1;
      _removeEmptyReason(_members[idx], _reasons[idx], _indexes[idx]);
    }
  }

  function _removeEmptyReason(address _of, bytes32 _reason, uint _index) internal {

    uint lastReasonIndex = lockReason[_of].length.sub(1, "TokenController: lockReason is empty");

    require(lockReason[_of][_index] == _reason, "TokenController: bad reason index");
    require(locked[_of][_reason].amount == 0, "TokenController: reason amount is not zero");

    if (lastReasonIndex != _index) {
      lockReason[_of][_index] = lockReason[_of][lastReasonIndex];
    }

    lockReason[_of].pop();
  }

  function initialize() external {
    require(claimSubmissionGracePeriod == 0, "TokenController: Already initialized");
    claimSubmissionGracePeriod = 120 days;
    migrate();
  }

  function migrate() internal {

    ClaimsData cd = ClaimsData(ms.getLatestAddress("CD"));
    uint totalClaims = cd.actualClaimLength() - 1;

    // fix stuck claims 21 & 22
    cd.changeFinalVerdict(20, -1);
    cd.setClaimStatus(20, 6);
    cd.changeFinalVerdict(21, -1);
    cd.setClaimStatus(21, 6);

    // reduce claim assessment lock period for members locked for more than 180 days
    // extracted using scripts/extract-ca-locked-more-than-180.js
    address payable[3] memory members = [
      0x4a9fA34da6d2378c8f3B9F6b83532B169beaEDFc,
      0x6b5DCDA27b5c3d88e71867D6b10b35372208361F,
      0x8B6D1e5b4db5B6f9aCcc659e2b9619B0Cd90D617
    ];

    for (uint i = 0; i < members.length; i++) {
      if (locked[members[i]]["CLA"].validity > now + 180 days) {
        locked[members[i]]["CLA"].validity = now + 180 days;
      }
    }

    for (uint i = 1; i <= totalClaims; i++) {

      (/*id*/, uint status) = cd.getClaimStatusNumber(i);
      (/*id*/, uint coverId) = cd.getClaimCoverId(i);
      int8 verdict = cd.getFinalVerdict(i);

      // SLOAD
      CoverInfo memory info = coverInfo[coverId];

      info.claimCount = info.claimCount + 1;
      info.hasAcceptedClaim = (status == 14);
      info.hasOpenClaim = (verdict == 0);

      // SSTORE
      coverInfo[coverId] = info;
    }
  }

}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../abstract/MasterAware.sol";
import "../cover/QuotationData.sol";
import "./NXMToken.sol";
import "./TokenController.sol";
import "./TokenData.sol";

contract TokenFunctions is MasterAware {
  using SafeMath for uint;

  TokenController public tc;
  NXMToken public tk;
  QuotationData public qd;

  event BurnCATokens(uint claimId, address addr, uint amount);

  /**
   * @dev to get the all the cover locked tokens of a user
   * @param _of is the user address in concern
   * @return amount locked
   */
  function getUserAllLockedCNTokens(address _of) external view returns (uint) {

    uint[] memory coverIds = qd.getAllCoversOfUser(_of);
    uint total;

    for (uint i = 0; i < coverIds.length; i++) {
      bytes32 reason = keccak256(abi.encodePacked("CN", _of, coverIds[i]));
      uint coverNote = tc.tokensLocked(_of, reason);
      total = total.add(coverNote);
    }

    return total;
  }

  /**
   * @dev Change Dependent Contract Address
   */
  function changeDependentContractAddress() public {
    tc = TokenController(master.getLatestAddress("TC"));
    tk = NXMToken(master.tokenAddress());
    qd = QuotationData(master.getLatestAddress("QD"));
  }

  /**
   * @dev Burns tokens used for fraudulent voting against a claim
   * @param claimid Claim Id.
   * @param _value number of tokens to be burned
   * @param _of Claim Assessor's address.
   */
  function burnCAToken(uint claimid, uint _value, address _of) external onlyGovernance {
    tc.burnLockedTokens(_of, "CLA", _value);
    emit BurnCATokens(claimid, _of, _value);
  }

  /**
   * @dev to check if a  member is locked for member vote
   * @param _of is the member address in concern
   * @return the boolean status
   */
  function isLockedForMemberVote(address _of) public view returns (bool) {
    return now < tk.isLockedForMV(_of);
  }

}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../abstract/Iupgradable.sol";

contract ClaimsData is Iupgradable {
  using SafeMath for uint;

  struct Claim {
    uint coverId;
    uint dateUpd;
  }

  struct Vote {
    address voter;
    uint tokens;
    uint claimId;
    int8 verdict;
    bool rewardClaimed;
  }

  struct ClaimsPause {
    uint coverid;
    uint dateUpd;
    bool submit;
  }

  struct ClaimPauseVoting {
    uint claimid;
    uint pendingTime;
    bool voting;
  }

  struct RewardDistributed {
    uint lastCAvoteIndex;
    uint lastMVvoteIndex;

  }

  struct ClaimRewardDetails {
    uint percCA;
    uint percMV;
    uint tokenToBeDist;

  }

  struct ClaimTotalTokens {
    uint accept;
    uint deny;
  }

  struct ClaimRewardStatus {
    uint percCA;
    uint percMV;
  }

  ClaimRewardStatus[] internal rewardStatus;

  Claim[] internal allClaims;
  Vote[] internal allvotes;
  ClaimsPause[] internal claimPause;
  ClaimPauseVoting[] internal claimPauseVotingEP;

  mapping(address => RewardDistributed) internal voterVoteRewardReceived;
  mapping(uint => ClaimRewardDetails) internal claimRewardDetail;
  mapping(uint => ClaimTotalTokens) internal claimTokensCA;
  mapping(uint => ClaimTotalTokens) internal claimTokensMV;
  mapping(uint => int8) internal claimVote;
  mapping(uint => uint) internal claimsStatus;
  mapping(uint => uint) internal claimState12Count;
  mapping(uint => uint[]) internal claimVoteCA;
  mapping(uint => uint[]) internal claimVoteMember;
  mapping(address => uint[]) internal voteAddressCA;
  mapping(address => uint[]) internal voteAddressMember;
  mapping(address => uint[]) internal allClaimsByAddress;
  mapping(address => mapping(uint => uint)) internal userClaimVoteCA;
  mapping(address => mapping(uint => uint)) internal userClaimVoteMember;
  mapping(address => uint) public userClaimVotePausedOn;

  uint internal claimPauseLastsubmit;
  uint internal claimStartVotingFirstIndex;
  uint public pendingClaimStart;
  uint public claimDepositTime;
  uint public maxVotingTime;
  uint public minVotingTime;
  uint public payoutRetryTime;
  uint public claimRewardPerc;
  uint public minVoteThreshold;
  uint public maxVoteThreshold;
  uint public majorityConsensus;
  uint public pauseDaysCA;

  event ClaimRaise(
    uint indexed coverId,
    address indexed userAddress,
    uint claimId,
    uint dateSubmit
  );

  event VoteCast(
    address indexed userAddress,
    uint indexed claimId,
    bytes4 indexed typeOf,
    uint tokens,
    uint submitDate,
    int8 verdict
  );

  constructor() public {
    pendingClaimStart = 1;
    maxVotingTime = 48 * 1 hours;
    minVotingTime = 12 * 1 hours;
    payoutRetryTime = 24 * 1 hours;
    allvotes.push(Vote(address(0), 0, 0, 0, false));
    allClaims.push(Claim(0, 0));
    claimDepositTime = 7 days;
    claimRewardPerc = 20;
    minVoteThreshold = 5;
    maxVoteThreshold = 10;
    majorityConsensus = 70;
    pauseDaysCA = 3 days;
    _addRewardIncentive();
  }

  /**
   * @dev Updates the pending claim start variable,
   * the lowest claim id with a pending decision/payout.
   */
  function setpendingClaimStart(uint _start) external onlyInternal {
    require(pendingClaimStart <= _start);
    pendingClaimStart = _start;
  }

  /**
   * @dev Updates the max vote index for which claim assessor has received reward
   * @param _voter address of the voter.
   * @param caIndex last index till which reward was distributed for CA
   */
  function setRewardDistributedIndexCA(address _voter, uint caIndex) external onlyInternal {
    voterVoteRewardReceived[_voter].lastCAvoteIndex = caIndex;

  }

  /**
   * @dev Used to pause claim assessor activity for 3 days
   * @param user Member address whose claim voting ability needs to be paused
   */
  function setUserClaimVotePausedOn(address user) external {
    require(ms.checkIsAuthToGoverned(msg.sender));
    userClaimVotePausedOn[user] = now;
  }

  /**
   * @dev Updates the max vote index for which member has received reward
   * @param _voter address of the voter.
   * @param mvIndex last index till which reward was distributed for member
   */
  function setRewardDistributedIndexMV(address _voter, uint mvIndex) external onlyInternal {

    voterVoteRewardReceived[_voter].lastMVvoteIndex = mvIndex;
  }

  /**
   * @param claimid claim id.
   * @param percCA reward Percentage reward for claim assessor
   * @param percMV reward Percentage reward for members
   * @param tokens total tokens to be rewarded
   */
  function setClaimRewardDetail(
    uint claimid,
    uint percCA,
    uint percMV,
    uint tokens
  )
  external
  onlyInternal
  {
    claimRewardDetail[claimid].percCA = percCA;
    claimRewardDetail[claimid].percMV = percMV;
    claimRewardDetail[claimid].tokenToBeDist = tokens;
  }

  /**
   * @dev Sets the reward claim status against a vote id.
   * @param _voteid vote Id.
   * @param claimed true if reward for vote is claimed, else false.
   */
  function setRewardClaimed(uint _voteid, bool claimed) external onlyInternal {
    allvotes[_voteid].rewardClaimed = claimed;
  }

  /**
   * @dev Sets the final vote's result(either accepted or declined)of a claim.
   * @param _claimId Claim Id.
   * @param _verdict 1 if claim is accepted,-1 if declined.
   */
  function changeFinalVerdict(uint _claimId, int8 _verdict) external onlyInternal {
    claimVote[_claimId] = _verdict;
  }

  /**
   * @dev Creates a new claim.
   */
  function addClaim(
    uint _claimId,
    uint _coverId,
    address _from,
    uint _nowtime
  )
  external
  onlyInternal
  {
    allClaims.push(Claim(_coverId, _nowtime));
    allClaimsByAddress[_from].push(_claimId);
  }

  /**
   * @dev Add Vote's details of a given claim.
   */
  function addVote(
    address _voter,
    uint _tokens,
    uint claimId,
    int8 _verdict
  )
  external
  onlyInternal
  {
    allvotes.push(Vote(_voter, _tokens, claimId, _verdict, false));
  }

  /**
   * @dev Stores the id of the claim assessor vote given to a claim.
   * Maintains record of all votes given by all the CA to a claim.
   * @param _claimId Claim Id to which vote has given by the CA.
   * @param _voteid Vote Id.
   */
  function addClaimVoteCA(uint _claimId, uint _voteid) external onlyInternal {
    claimVoteCA[_claimId].push(_voteid);
  }

  /**
   * @dev Sets the id of the vote.
   * @param _from Claim assessor's address who has given the vote.
   * @param _claimId Claim Id for which vote has been given by the CA.
   * @param _voteid Vote Id which will be stored against the given _from and claimid.
   */
  function setUserClaimVoteCA(
    address _from,
    uint _claimId,
    uint _voteid
  )
  external
  onlyInternal
  {
    userClaimVoteCA[_from][_claimId] = _voteid;
    voteAddressCA[_from].push(_voteid);
  }

  /**
   * @dev Stores the tokens locked by the Claim Assessors during voting of a given claim.
   * @param _claimId Claim Id.
   * @param _vote 1 for accept and increases the tokens of claim as accept,
   * -1 for deny and increases the tokens of claim as deny.
   * @param _tokens Number of tokens.
   */
  function setClaimTokensCA(uint _claimId, int8 _vote, uint _tokens) external onlyInternal {
    if (_vote == 1)
      claimTokensCA[_claimId].accept = claimTokensCA[_claimId].accept.add(_tokens);
    if (_vote == - 1)
      claimTokensCA[_claimId].deny = claimTokensCA[_claimId].deny.add(_tokens);
  }

  /**
   * @dev Stores the tokens locked by the Members during voting of a given claim.
   * @param _claimId Claim Id.
   * @param _vote 1 for accept and increases the tokens of claim as accept,
   * -1 for deny and increases the tokens of claim as deny.
   * @param _tokens Number of tokens.
   */
  function setClaimTokensMV(uint _claimId, int8 _vote, uint _tokens) external onlyInternal {
    if (_vote == 1)
      claimTokensMV[_claimId].accept = claimTokensMV[_claimId].accept.add(_tokens);
    if (_vote == - 1)
      claimTokensMV[_claimId].deny = claimTokensMV[_claimId].deny.add(_tokens);
  }

  /**
   * @dev Stores the id of the member vote given to a claim.
   * Maintains record of all votes given by all the Members to a claim.
   * @param _claimId Claim Id to which vote has been given by the Member.
   * @param _voteid Vote Id.
   */
  function addClaimVotemember(uint _claimId, uint _voteid) external onlyInternal {
    claimVoteMember[_claimId].push(_voteid);
  }

  /**
   * @dev Sets the id of the vote.
   * @param _from Member's address who has given the vote.
   * @param _claimId Claim Id for which vote has been given by the Member.
   * @param _voteid Vote Id which will be stored against the given _from and claimid.
   */
  function setUserClaimVoteMember(
    address _from,
    uint _claimId,
    uint _voteid
  )
  external
  onlyInternal
  {
    userClaimVoteMember[_from][_claimId] = _voteid;
    voteAddressMember[_from].push(_voteid);

  }

  /**
   * @dev Increases the count of failure until payout of a claim is successful.
   */
  function updateState12Count(uint _claimId, uint _cnt) external onlyInternal {
    claimState12Count[_claimId] = claimState12Count[_claimId].add(_cnt);
  }

  /**
   * @dev Sets status of a claim.
   * @param _claimId Claim Id.
   * @param _stat Status number.
   */
  function setClaimStatus(uint _claimId, uint _stat) external onlyInternal {
    claimsStatus[_claimId] = _stat;
  }

  /**
   * @dev Sets the timestamp of a given claim at which the Claim's details has been updated.
   * @param _claimId Claim Id of claim which has been changed.
   * @param _dateUpd timestamp at which claim is updated.
   */
  function setClaimdateUpd(uint _claimId, uint _dateUpd) external onlyInternal {
    allClaims[_claimId].dateUpd = _dateUpd;
  }

  /**
   @dev Queues Claims during Emergency Pause.
   */
  function setClaimAtEmergencyPause(
    uint _coverId,
    uint _dateUpd,
    bool _submit
  )
  external
  onlyInternal
  {
    claimPause.push(ClaimsPause(_coverId, _dateUpd, _submit));
  }

  /**
   * @dev Set submission flag for Claims queued during emergency pause.
   * Set to true after EP is turned off and the claim is submitted .
   */
  function setClaimSubmittedAtEPTrue(uint _index, bool _submit) external onlyInternal {
    claimPause[_index].submit = _submit;
  }

  /**
   * @dev Sets the index from which claim needs to be
   * submitted when emergency pause is swithched off.
   */
  function setFirstClaimIndexToSubmitAfterEP(
    uint _firstClaimIndexToSubmit
  )
  external
  onlyInternal
  {
    claimPauseLastsubmit = _firstClaimIndexToSubmit;
  }

  /**
   * @dev Sets the pending vote duration for a claim in case of emergency pause.
   */
  function setPendingClaimDetails(
    uint _claimId,
    uint _pendingTime,
    bool _voting
  )
  external
  onlyInternal
  {
    claimPauseVotingEP.push(ClaimPauseVoting(_claimId, _pendingTime, _voting));
  }

  /**
   * @dev Sets voting flag true after claim is reopened for voting after emergency pause.
   */
  function setPendingClaimVoteStatus(uint _claimId, bool _vote) external onlyInternal {
    claimPauseVotingEP[_claimId].voting = _vote;
  }

  /**
   * @dev Sets the index from which claim needs to be
   * reopened when emergency pause is swithched off.
   */
  function setFirstClaimIndexToStartVotingAfterEP(
    uint _claimStartVotingFirstIndex
  )
  external
  onlyInternal
  {
    claimStartVotingFirstIndex = _claimStartVotingFirstIndex;
  }

  /**
   * @dev Calls Vote Event.
   */
  function callVoteEvent(
    address _userAddress,
    uint _claimId,
    bytes4 _typeOf,
    uint _tokens,
    uint _submitDate,
    int8 _verdict
  )
  external
  onlyInternal
  {
    emit VoteCast(
      _userAddress,
      _claimId,
      _typeOf,
      _tokens,
      _submitDate,
      _verdict
    );
  }

  /**
   * @dev Calls Claim Event.
   */
  function callClaimEvent(
    uint _coverId,
    address _userAddress,
    uint _claimId,
    uint _datesubmit
  )
  external
  onlyInternal
  {
    emit ClaimRaise(_coverId, _userAddress, _claimId, _datesubmit);
  }

  /**
   * @dev Gets Uint Parameters by parameter code
   * @param code whose details we want
   * @return string value of the parameter
   * @return associated amount (time or perc or value) to the code
   */
  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {
    codeVal = code;
    if (code == "CAMAXVT") {
      val = maxVotingTime / (1 hours);

    } else if (code == "CAMINVT") {

      val = minVotingTime / (1 hours);

    } else if (code == "CAPRETRY") {

      val = payoutRetryTime / (1 hours);

    } else if (code == "CADEPT") {

      val = claimDepositTime / (1 days);

    } else if (code == "CAREWPER") {

      val = claimRewardPerc;

    } else if (code == "CAMINTH") {

      val = minVoteThreshold;

    } else if (code == "CAMAXTH") {

      val = maxVoteThreshold;

    } else if (code == "CACONPER") {

      val = majorityConsensus;

    } else if (code == "CAPAUSET") {
      val = pauseDaysCA / (1 days);
    }

  }

  /**
   * @dev Get claim queued during emergency pause by index.
   */
  function getClaimOfEmergencyPauseByIndex(
    uint _index
  )
  external
  view
  returns (
    uint coverId,
    uint dateUpd,
    bool submit
  )
  {
    coverId = claimPause[_index].coverid;
    dateUpd = claimPause[_index].dateUpd;
    submit = claimPause[_index].submit;
  }

  /**
   * @dev Gets the Claim's details of given claimid.
   */
  function getAllClaimsByIndex(
    uint _claimId
  )
  external
  view
  returns (
    uint coverId,
    int8 vote,
    uint status,
    uint dateUpd,
    uint state12Count
  )
  {
    return (
    allClaims[_claimId].coverId,
    claimVote[_claimId],
    claimsStatus[_claimId],
    allClaims[_claimId].dateUpd,
    claimState12Count[_claimId]
    );
  }

  /**
   * @dev Gets the vote id of a given claim of a given Claim Assessor.
   */
  function getUserClaimVoteCA(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote)
  {
    return userClaimVoteCA[_add][_claimId];
  }

  /**
   * @dev Gets the vote id of a given claim of a given member.
   */
  function getUserClaimVoteMember(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote)
  {
    return userClaimVoteMember[_add][_claimId];
  }

  /**
   * @dev Gets the count of all votes.
   */
  function getAllVoteLength() external view returns (uint voteCount) {
    return allvotes.length.sub(1); // Start Index always from 1.
  }

  /**
   * @dev Gets the status number of a given claim.
   * @param _claimId Claim id.
   * @return statno Status Number.
   */
  function getClaimStatusNumber(uint _claimId) external view returns (uint claimId, uint statno) {
    return (_claimId, claimsStatus[_claimId]);
  }

  /**
   * @dev Gets the reward percentage to be distributed for a given status id
   * @param statusNumber the number of type of status
   * @return percCA reward Percentage for claim assessor
   * @return percMV reward Percentage for members
   */
  function getRewardStatus(uint statusNumber) external view returns (uint percCA, uint percMV) {
    return (rewardStatus[statusNumber].percCA, rewardStatus[statusNumber].percMV);
  }

  /**
   * @dev Gets the number of tries that have been made for a successful payout of a Claim.
   */
  function getClaimState12Count(uint _claimId) external view returns (uint num) {
    num = claimState12Count[_claimId];
  }

  /**
   * @dev Gets the last update date of a claim.
   */
  function getClaimDateUpd(uint _claimId) external view returns (uint dateupd) {
    dateupd = allClaims[_claimId].dateUpd;
  }

  /**
   * @dev Gets all Claims created by a user till date.
   * @param _member user's address.
   * @return claimarr List of Claims id.
   */
  function getAllClaimsByAddress(address _member) external view returns (uint[] memory claimarr) {
    return allClaimsByAddress[_member];
  }

  /**
   * @dev Gets the number of tokens that has been locked
   * while giving vote to a claim by  Claim Assessors.
   * @param _claimId Claim Id.
   * @return accept Total number of tokens when CA accepts the claim.
   * @return deny Total number of tokens when CA declines the claim.
   */
  function getClaimsTokenCA(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  )
  {
    return (
    _claimId,
    claimTokensCA[_claimId].accept,
    claimTokensCA[_claimId].deny
    );
  }

  /**
   * @dev Gets the number of tokens that have been
   * locked while assessing a claim as a member.
   * @param _claimId Claim Id.
   * @return accept Total number of tokens in acceptance of the claim.
   * @return deny Total number of tokens against the claim.
   */
  function getClaimsTokenMV(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  )
  {
    return (
    _claimId,
    claimTokensMV[_claimId].accept,
    claimTokensMV[_claimId].deny
    );
  }

  /**
   * @dev Gets the total number of votes cast as Claims assessor for/against a given claim
   */
  function getCaClaimVotesToken(uint _claimId) external view returns (uint claimId, uint cnt) {
    claimId = _claimId;
    cnt = 0;
    for (uint i = 0; i < claimVoteCA[_claimId].length; i++) {
      cnt = cnt.add(allvotes[claimVoteCA[_claimId][i]].tokens);
    }
  }

  /**
   * @dev Gets the total number of tokens cast as a member for/against a given claim
   */
  function getMemberClaimVotesToken(
    uint _claimId
  )
  external
  view
  returns (uint claimId, uint cnt)
  {
    claimId = _claimId;
    cnt = 0;
    for (uint i = 0; i < claimVoteMember[_claimId].length; i++) {
      cnt = cnt.add(allvotes[claimVoteMember[_claimId][i]].tokens);
    }
  }

  /**
   * @dev Provides information of a vote when given its vote id.
   * @param _voteid Vote Id.
   */
  function getVoteDetails(uint _voteid)
  external view
  returns (
    uint tokens,
    uint claimId,
    int8 verdict,
    bool rewardClaimed
  )
  {
    return (
    allvotes[_voteid].tokens,
    allvotes[_voteid].claimId,
    allvotes[_voteid].verdict,
    allvotes[_voteid].rewardClaimed
    );
  }

  /**
   * @dev Gets the voter's address of a given vote id.
   */
  function getVoterVote(uint _voteid) external view returns (address voter) {
    return allvotes[_voteid].voter;
  }

  /**
   * @dev Provides information of a Claim when given its claim id.
   * @param _claimId Claim Id.
   */
  function getClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint coverId,
    int8 vote,
    uint status,
    uint dateUpd,
    uint state12Count
  )
  {
    return (
    _claimId,
    allClaims[_claimId].coverId,
    claimVote[_claimId],
    claimsStatus[_claimId],
    allClaims[_claimId].dateUpd,
    claimState12Count[_claimId]
    );
  }

  /**
   * @dev Gets the total number of votes of a given claim.
   * @param _claimId Claim Id.
   * @param _ca if 1: votes given by Claim Assessors to a claim,
   * else returns the number of votes of given by Members to a claim.
   * @return len total number of votes for/against a given claim.
   */
  function getClaimVoteLength(
    uint _claimId,
    uint8 _ca
  )
  external
  view
  returns (uint claimId, uint len)
  {
    claimId = _claimId;
    if (_ca == 1)
      len = claimVoteCA[_claimId].length;
    else
      len = claimVoteMember[_claimId].length;
  }

  /**
   * @dev Gets the verdict of a vote using claim id and index.
   * @param _ca 1 for vote given as a CA, else for vote given as a member.
   * @return ver 1 if vote was given in favour,-1 if given in against.
   */
  function getVoteVerdict(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (int8 ver)
  {
    if (_ca == 1)
      ver = allvotes[claimVoteCA[_claimId][_index]].verdict;
    else
      ver = allvotes[claimVoteMember[_claimId][_index]].verdict;
  }

  /**
   * @dev Gets the Number of tokens of a vote using claim id and index.
   * @param _ca 1 for vote given as a CA, else for vote given as a member.
   * @return tok Number of tokens.
   */
  function getVoteToken(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (uint tok)
  {
    if (_ca == 1)
      tok = allvotes[claimVoteCA[_claimId][_index]].tokens;
    else
      tok = allvotes[claimVoteMember[_claimId][_index]].tokens;
  }

  /**
   * @dev Gets the Voter's address of a vote using claim id and index.
   * @param _ca 1 for vote given as a CA, else for vote given as a member.
   * @return voter Voter's address.
   */
  function getVoteVoter(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (address voter)
  {
    if (_ca == 1)
      voter = allvotes[claimVoteCA[_claimId][_index]].voter;
    else
      voter = allvotes[claimVoteMember[_claimId][_index]].voter;
  }

  /**
   * @dev Gets total number of Claims created by a user till date.
   * @param _add User's address.
   */
  function getUserClaimCount(address _add) external view returns (uint len) {
    len = allClaimsByAddress[_add].length;
  }

  /**
   * @dev Calculates number of Claims that are in pending state.
   */
  function getClaimLength() external view returns (uint len) {
    len = allClaims.length.sub(pendingClaimStart);
  }

  /**
   * @dev Gets the Number of all the Claims created till date.
   */
  function actualClaimLength() external view returns (uint len) {
    len = allClaims.length;
  }

  /**
   * @dev Gets details of a claim.
   * @param _index claim id = pending claim start + given index
   * @param _add User's address.
   * @return coverid cover against which claim has been submitted.
   * @return claimId Claim  Id.
   * @return voteCA verdict of vote given as a Claim Assessor.
   * @return voteMV verdict of vote given as a Member.
   * @return statusnumber Status of claim.
   */
  function getClaimFromNewStart(
    uint _index,
    address _add
  )
  external
  view
  returns (
    uint coverid,
    uint claimId,
    int8 voteCA,
    int8 voteMV,
    uint statusnumber
  )
  {
    uint i = pendingClaimStart.add(_index);
    coverid = allClaims[i].coverId;
    claimId = i;
    if (userClaimVoteCA[_add][i] > 0)
      voteCA = allvotes[userClaimVoteCA[_add][i]].verdict;
    else
      voteCA = 0;

    if (userClaimVoteMember[_add][i] > 0)
      voteMV = allvotes[userClaimVoteMember[_add][i]].verdict;
    else
      voteMV = 0;

    statusnumber = claimsStatus[i];
  }

  /**
   * @dev Gets details of a claim of a user at a given index.
   */
  function getUserClaimByIndex(
    uint _index,
    address _add
  )
  external
  view
  returns (
    uint status,
    uint coverid,
    uint claimId
  )
  {
    claimId = allClaimsByAddress[_add][_index];
    status = claimsStatus[claimId];
    coverid = allClaims[claimId].coverId;
  }

  /**
   * @dev Gets Id of all the votes given to a claim.
   * @param _claimId Claim Id.
   * @return ca id of all the votes given by Claim assessors to a claim.
   * @return mv id of all the votes given by members to a claim.
   */
  function getAllVotesForClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint[] memory ca,
    uint[] memory mv
  )
  {
    return (_claimId, claimVoteCA[_claimId], claimVoteMember[_claimId]);
  }

  /**
   * @dev Gets Number of tokens deposit in a vote using
   * Claim assessor's address and claim id.
   * @return tokens Number of deposited tokens.
   */
  function getTokensClaim(
    address _of,
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint tokens
  )
  {
    return (_claimId, allvotes[userClaimVoteCA[_of][_claimId]].tokens);
  }

  /**
   * @param _voter address of the voter.
   * @return lastCAvoteIndex last index till which reward was distributed for CA
   * @return lastMVvoteIndex last index till which reward was distributed for member
   */
  function getRewardDistributedIndex(
    address _voter
  )
  external
  view
  returns (
    uint lastCAvoteIndex,
    uint lastMVvoteIndex
  )
  {
    return (
    voterVoteRewardReceived[_voter].lastCAvoteIndex,
    voterVoteRewardReceived[_voter].lastMVvoteIndex
    );
  }

  /**
   * @param claimid claim id.
   * @return perc_CA reward Percentage for claim assessor
   * @return perc_MV reward Percentage for members
   * @return tokens total tokens to be rewarded
   */
  function getClaimRewardDetail(
    uint claimid
  )
  external
  view
  returns (
    uint percCA,
    uint percMV,
    uint tokens
  )
  {
    return (
    claimRewardDetail[claimid].percCA,
    claimRewardDetail[claimid].percMV,
    claimRewardDetail[claimid].tokenToBeDist
    );
  }

  /**
   * @dev Gets cover id of a claim.
   */
  function getClaimCoverId(uint _claimId) external view returns (uint claimId, uint coverid) {
    return (_claimId, allClaims[_claimId].coverId);
  }

  /**
   * @dev Gets total number of tokens staked during voting by Claim Assessors.
   * @param _claimId Claim Id.
   * @param _verdict 1 to get total number of accept tokens, -1 to get total number of deny tokens.
   * @return token token Number of tokens(either accept or deny on the basis of verdict given as parameter).
   */
  function getClaimVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token) {
    claimId = _claimId;
    token = 0;
    for (uint i = 0; i < claimVoteCA[_claimId].length; i++) {
      if (allvotes[claimVoteCA[_claimId][i]].verdict == _verdict)
        token = token.add(allvotes[claimVoteCA[_claimId][i]].tokens);
    }
  }

  /**
   * @dev Gets total number of tokens staked during voting by Members.
   * @param _claimId Claim Id.
   * @param _verdict 1 to get total number of accept tokens,
   *  -1 to get total number of deny tokens.
   * @return token token Number of tokens(either accept or
   * deny on the basis of verdict given as parameter).
   */
  function getClaimMVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token) {
    claimId = _claimId;
    token = 0;
    for (uint i = 0; i < claimVoteMember[_claimId].length; i++) {
      if (allvotes[claimVoteMember[_claimId][i]].verdict == _verdict)
        token = token.add(allvotes[claimVoteMember[_claimId][i]].tokens);
    }
  }

  /**
   * @param _voter address  of voteid
   * @param index index to get voteid in CA
   */
  function getVoteAddressCA(address _voter, uint index) external view returns (uint) {
    return voteAddressCA[_voter][index];
  }

  /**
   * @param _voter address  of voter
   * @param index index to get voteid in member vote
   */
  function getVoteAddressMember(address _voter, uint index) external view returns (uint) {
    return voteAddressMember[_voter][index];
  }

  /**
   * @param _voter address  of voter
   */
  function getVoteAddressCALength(address _voter) external view returns (uint) {
    return voteAddressCA[_voter].length;
  }

  /**
   * @param _voter address  of voter
   */
  function getVoteAddressMemberLength(address _voter) external view returns (uint) {
    return voteAddressMember[_voter].length;
  }

  /**
   * @dev Gets the Final result of voting of a claim.
   * @param _claimId Claim id.
   * @return verdict 1 if claim is accepted, -1 if declined.
   */
  function getFinalVerdict(uint _claimId) external view returns (int8 verdict) {
    return claimVote[_claimId];
  }

  /**
   * @dev Get number of Claims queued for submission during emergency pause.
   */
  function getLengthOfClaimSubmittedAtEP() external view returns (uint len) {
    len = claimPause.length;
  }

  /**
   * @dev Gets the index from which claim needs to be
   * submitted when emergency pause is swithched off.
   */
  function getFirstClaimIndexToSubmitAfterEP() external view returns (uint indexToSubmit) {
    indexToSubmit = claimPauseLastsubmit;
  }

  /**
   * @dev Gets number of Claims to be reopened for voting post emergency pause period.
   */
  function getLengthOfClaimVotingPause() external view returns (uint len) {
    len = claimPauseVotingEP.length;
  }

  /**
   * @dev Gets claim details to be reopened for voting after emergency pause.
   */
  function getPendingClaimDetailsByIndex(
    uint _index
  )
  external
  view
  returns (
    uint claimId,
    uint pendingTime,
    bool voting
  )
  {
    claimId = claimPauseVotingEP[_index].claimid;
    pendingTime = claimPauseVotingEP[_index].pendingTime;
    voting = claimPauseVotingEP[_index].voting;
  }

  /**
   * @dev Gets the index from which claim needs to be reopened when emergency pause is swithched off.
   */
  function getFirstClaimIndexToStartVotingAfterEP() external view returns (uint firstindex) {
    firstindex = claimStartVotingFirstIndex;
  }

  /**
   * @dev Updates Uint Parameters of a code
   * @param code whose details we want to update
   * @param val value to set
   */
  function updateUintParameters(bytes8 code, uint val) public {
    require(ms.checkIsAuthToGoverned(msg.sender));
    if (code == "CAMAXVT") {
      _setMaxVotingTime(val * 1 hours);

    } else if (code == "CAMINVT") {

      _setMinVotingTime(val * 1 hours);

    } else if (code == "CAPRETRY") {

      _setPayoutRetryTime(val * 1 hours);

    } else if (code == "CADEPT") {

      _setClaimDepositTime(val * 1 days);

    } else if (code == "CAREWPER") {

      _setClaimRewardPerc(val);

    } else if (code == "CAMINTH") {

      _setMinVoteThreshold(val);

    } else if (code == "CAMAXTH") {

      _setMaxVoteThreshold(val);

    } else if (code == "CACONPER") {

      _setMajorityConsensus(val);

    } else if (code == "CAPAUSET") {
      _setPauseDaysCA(val * 1 days);
    } else {

      revert("Invalid param code");
    }

  }

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public onlyInternal {}

  /**
   * @dev Adds status under which a claim can lie.
   * @param percCA reward percentage for claim assessor
   * @param percMV reward percentage for members
   */
  function _pushStatus(uint percCA, uint percMV) internal {
    rewardStatus.push(ClaimRewardStatus(percCA, percMV));
  }

  /**
   * @dev adds reward incentive for all possible claim status for Claim assessors and members
   */
  function _addRewardIncentive() internal {
    _pushStatus(0, 0); // 0  Pending-Claim Assessor Vote
    _pushStatus(0, 0); // 1 Pending-Claim Assessor Vote Denied, Pending Member Vote
    _pushStatus(0, 0); // 2 Pending-CA Vote Threshold not Reached Accept, Pending Member Vote
    _pushStatus(0, 0); // 3 Pending-CA Vote Threshold not Reached Deny, Pending Member Vote
    _pushStatus(0, 0); // 4 Pending-CA Consensus not reached Accept, Pending Member Vote
    _pushStatus(0, 0); // 5 Pending-CA Consensus not reached Deny, Pending Member Vote
    _pushStatus(100, 0); // 6 Final-Claim Assessor Vote Denied
    _pushStatus(100, 0); // 7 Final-Claim Assessor Vote Accepted
    _pushStatus(0, 100); // 8 Final-Claim Assessor Vote Denied, MV Accepted
    _pushStatus(0, 100); // 9 Final-Claim Assessor Vote Denied, MV Denied
    _pushStatus(0, 0); // 10 Final-Claim Assessor Vote Accept, MV Nodecision
    _pushStatus(0, 0); // 11 Final-Claim Assessor Vote Denied, MV Nodecision
    _pushStatus(0, 0); // 12 Claim Accepted Payout Pending
    _pushStatus(0, 0); // 13 Claim Accepted No Payout
    _pushStatus(0, 0); // 14 Claim Accepted Payout Done
  }

  /**
   * @dev Sets Maximum time(in seconds) for which claim assessment voting is open
   */
  function _setMaxVotingTime(uint _time) internal {
    maxVotingTime = _time;
  }

  /**
   *  @dev Sets Minimum time(in seconds) for which claim assessment voting is open
   */
  function _setMinVotingTime(uint _time) internal {
    minVotingTime = _time;
  }

  /**
   *  @dev Sets Minimum vote threshold required
   */
  function _setMinVoteThreshold(uint val) internal {
    minVoteThreshold = val;
  }

  /**
   *  @dev Sets Maximum vote threshold required
   */
  function _setMaxVoteThreshold(uint val) internal {
    maxVoteThreshold = val;
  }

  /**
   *  @dev Sets the value considered as Majority Consenus in voting
   */
  function _setMajorityConsensus(uint val) internal {
    majorityConsensus = val;
  }

  /**
   * @dev Sets the payout retry time
   */
  function _setPayoutRetryTime(uint _time) internal {
    payoutRetryTime = _time;
  }

  /**
   *  @dev Sets percentage of reward given for claim assessment
   */
  function _setClaimRewardPerc(uint _val) internal {

    claimRewardPerc = _val;
  }

  /**
   * @dev Sets the time for which claim is deposited.
   */
  function _setClaimDepositTime(uint _time) internal {

    claimDepositTime = _time;
  }

  /**
   *  @dev Sets number of days claim assessment will be paused
   */
  function _setPauseDaysCA(uint val) internal {
    pauseDaysCA = val;
  }
}

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../abstract/MasterAware.sol";
import "../../interfaces/IPooledStaking.sol";
import "../capital/Pool.sol";
import "../claims/ClaimsData.sol";
import "../claims/ClaimsReward.sol";
import "../cover/QuotationData.sol";
import "../governance/MemberRoles.sol";
import "../token/TokenController.sol";
import "../capital/MCR.sol";

contract Incidents is MasterAware {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  struct Incident {
    address productId;
    uint32 date;
    uint priceBefore;
  }

  // contract identifiers
  enum ID {CD, CR, QD, TC, MR, P1, PS, MC}

  mapping(uint => address payable) public internalContracts;

  Incident[] public incidents;

  // product id => underlying token (ex. yDAI -> DAI)
  mapping(address => address) public underlyingToken;

  // product id => covered token (ex. 0xc7ed.....1 -> yDAI)
  mapping(address => address) public coveredToken;

  // claim id => payout amount
  mapping(uint => uint) public claimPayout;

  // product id => accumulated burn amount
  mapping(address => uint) public accumulatedBurn;

  // burn ratio in bps, ex 2000 for 20%
  uint public BURN_RATIO;

  // burn ratio in bps
  uint public DEDUCTIBLE_RATIO;

  uint constant BASIS_PRECISION = 10000;

  event ProductAdded(
    address indexed productId,
    address indexed coveredToken,
    address indexed underlyingToken
  );

  event IncidentAdded(
    address indexed productId,
    uint incidentDate,
    uint priceBefore
  );

  modifier onlyAdvisoryBoard {
    uint abRole = uint(MemberRoles.Role.AdvisoryBoard);
    require(
      memberRoles().checkRole(msg.sender, abRole),
      "Incidents: Caller is not an advisory board member"
    );
    _;
  }

  function initialize() external {
    require(BURN_RATIO == 0, "Already initialized");
    BURN_RATIO = 2000;
    DEDUCTIBLE_RATIO = 9000;
  }

  function addProducts(
    address[] calldata _productIds,
    address[] calldata _coveredTokens,
    address[] calldata _underlyingTokens
  ) external onlyAdvisoryBoard {

    require(
      _productIds.length == _coveredTokens.length,
      "Incidents: Protocols and covered tokens lengths differ"
    );

    require(
      _productIds.length == _underlyingTokens.length,
      "Incidents: Protocols and underyling tokens lengths differ"
    );

    for (uint i = 0; i < _productIds.length; i++) {
      address id = _productIds[i];

      require(coveredToken[id] == address(0), "Incidents: covered token is already set");
      require(underlyingToken[id] == address(0), "Incidents: underlying token is already set");

      coveredToken[id] = _coveredTokens[i];
      underlyingToken[id] = _underlyingTokens[i];
      emit ProductAdded(id, _coveredTokens[i], _underlyingTokens[i]);
    }
  }

  function incidentCount() external view returns (uint) {
    return incidents.length;
  }

  function addIncident(
    address productId,
    uint incidentDate,
    uint priceBefore
  ) external onlyGovernance {
    address underlying = underlyingToken[productId];
    require(underlying != address(0), "Incidents: Unsupported product");

    Incident memory incident = Incident(productId, uint32(incidentDate), priceBefore);
    incidents.push(incident);

    emit IncidentAdded(productId, incidentDate, priceBefore);
  }

  function redeemPayoutForMember(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount,
    address member
  ) external onlyInternal returns (uint claimId, uint payoutAmount, address payoutToken) {
    (claimId, payoutAmount, payoutToken) = _redeemPayout(coverId, incidentId, coveredTokenAmount, member);
  }

  function redeemPayout(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount
  ) external returns (uint claimId, uint payoutAmount, address payoutToken) {
    (claimId, payoutAmount, payoutToken) = _redeemPayout(coverId, incidentId, coveredTokenAmount, msg.sender);
  }

  function _redeemPayout(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount,
    address coverOwner
  ) internal returns (uint claimId, uint payoutAmount, address coverAsset) {
    QuotationData qd = quotationData();
    Incident memory incident = incidents[incidentId];
    uint sumAssured;
    bytes4 currency;

    {
      address productId;
      address _coverOwner;

      (/* id */, _coverOwner, productId,
       currency, sumAssured, /* premiumNXM */
      ) = qd.getCoverDetailsByCoverID1(coverId);

      // check ownership and covered protocol
      require(coverOwner == _coverOwner, "Incidents: Not cover owner");
      require(productId == incident.productId, "Incidents: Bad incident id");
    }

    {
      uint coverPeriod = uint(qd.getCoverPeriod(coverId)).mul(1 days);
      uint coverExpirationDate = qd.getValidityOfCover(coverId);
      uint coverStartDate = coverExpirationDate.sub(coverPeriod);

      // check cover validity
      require(coverStartDate <= incident.date, "Incidents: Cover start date is after the incident");
      require(coverExpirationDate >= incident.date, "Incidents: Cover end date is before the incident");

      // check grace period
      uint gracePeriod = tokenController().claimSubmissionGracePeriod();
      require(coverExpirationDate.add(gracePeriod) >= block.timestamp, "Incidents: Grace period has expired");
    }

    {
      // assumes 18 decimals (eth & dai)
      uint decimalPrecision = 1e18;
      uint maxAmount;

      // sumAssured is currently stored without decimals
      uint coverAmount = sumAssured.mul(decimalPrecision);

      {
        // max amount check
        uint deductiblePriceBefore = incident.priceBefore.mul(DEDUCTIBLE_RATIO).div(BASIS_PRECISION);
        maxAmount = coverAmount.mul(decimalPrecision).div(deductiblePriceBefore);
        require(coveredTokenAmount <= maxAmount, "Incidents: Amount exceeds sum assured");
      }

      // payoutAmount = coveredTokenAmount / maxAmount * coverAmount
      //              = coveredTokenAmount * coverAmount / maxAmount
      payoutAmount = coveredTokenAmount.mul(coverAmount).div(maxAmount);
    }

    {
      TokenController tc = tokenController();
      // mark cover as having a successful claim
      tc.markCoverClaimOpen(coverId);
      tc.markCoverClaimClosed(coverId, true);

      // create the claim
      ClaimsData cd = claimsData();
      claimId = cd.actualClaimLength();
      cd.addClaim(claimId, coverId, coverOwner, now);
      cd.callClaimEvent(coverId, coverOwner, claimId, now);
      cd.setClaimStatus(claimId, 14);
      qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.ClaimAccepted));

      claimPayout[claimId] = payoutAmount;
    }

    coverAsset = claimsReward().getCurrencyAssetAddress(currency);

    _sendPayoutAndPushBurn(
      incident.productId,
      address(uint160(coverOwner)),
      coveredTokenAmount,
      coverAsset,
      payoutAmount
    );

    qd.subFromTotalSumAssured(currency, sumAssured);
    qd.subFromTotalSumAssuredSC(incident.productId, currency, sumAssured);

    mcr().updateMCRInternal(pool().getPoolValueInEth(), true);
  }

  function pushBurns(address productId, uint maxIterations) external {

    uint burnAmount = accumulatedBurn[productId];
    delete accumulatedBurn[productId];

    require(burnAmount > 0, "Incidents: No burns to push");
    require(maxIterations >= 30, "Incidents: Pass at least 30 iterations");

    IPooledStaking ps = pooledStaking();
    ps.pushBurn(productId, burnAmount);
    ps.processPendingActions(maxIterations);
  }

  function withdrawAsset(address asset, address destination, uint amount) external onlyGovernance {
    IERC20 token = IERC20(asset);
    uint balance = token.balanceOf(address(this));
    uint transferAmount = amount > balance ? balance : amount;
    token.safeTransfer(destination, transferAmount);
  }

  function _sendPayoutAndPushBurn(
    address productId,
    address payable coverOwner,
    uint coveredTokenAmount,
    address coverAsset,
    uint payoutAmount
  ) internal {

    address _coveredToken = coveredToken[productId];

    // pull depegged tokens
    IERC20(_coveredToken).safeTransferFrom(msg.sender, address(this), coveredTokenAmount);

    Pool p1 = pool();

    // send the payoutAmount
    {
      address payable payoutAddress = memberRoles().getClaimPayoutAddress(coverOwner);
      bool success = p1.sendClaimPayout(coverAsset, payoutAddress, payoutAmount);
      require(success, "Incidents: Payout failed");
    }

    {
      // burn
      uint decimalPrecision = 1e18;
      uint assetPerNxm = p1.getTokenPrice(coverAsset);
      uint maxBurnAmount = payoutAmount.mul(decimalPrecision).div(assetPerNxm);
      uint burnAmount = maxBurnAmount.mul(BURN_RATIO).div(BASIS_PRECISION);

      accumulatedBurn[productId] = accumulatedBurn[productId].add(burnAmount);
    }
  }

  function claimsData() internal view returns (ClaimsData) {
    return ClaimsData(internalContracts[uint(ID.CD)]);
  }

  function claimsReward() internal view returns (ClaimsReward) {
    return ClaimsReward(internalContracts[uint(ID.CR)]);
  }

  function quotationData() internal view returns (QuotationData) {
    return QuotationData(internalContracts[uint(ID.QD)]);
  }

  function tokenController() internal view returns (TokenController) {
    return TokenController(internalContracts[uint(ID.TC)]);
  }

  function memberRoles() internal view returns (MemberRoles) {
    return MemberRoles(internalContracts[uint(ID.MR)]);
  }

  function pool() internal view returns (Pool) {
    return Pool(internalContracts[uint(ID.P1)]);
  }

  function pooledStaking() internal view returns (IPooledStaking) {
    return IPooledStaking(internalContracts[uint(ID.PS)]);
  }

  function mcr() internal view returns (MCR) {
    return MCR(internalContracts[uint(ID.MC)]);
  }

  function updateUintParameters(bytes8 code, uint value) external onlyGovernance {

    if (code == "BURNRATE") {
      require(value <= BASIS_PRECISION, "Incidents: Burn ratio cannot exceed 10000");
      BURN_RATIO = value;
      return;
    }

    if (code == "DEDUCTIB") {
      require(value <= BASIS_PRECISION, "Incidents: Deductible ratio cannot exceed 10000");
      DEDUCTIBLE_RATIO = value;
      return;
    }

    revert("Incidents: Invalid parameter");
  }

  function changeDependentContractAddress() external {
    INXMMaster master = INXMMaster(master);
    internalContracts[uint(ID.CD)] = master.getLatestAddress("CD");
    internalContracts[uint(ID.CR)] = master.getLatestAddress("CR");
    internalContracts[uint(ID.QD)] = master.getLatestAddress("QD");
    internalContracts[uint(ID.TC)] = master.getLatestAddress("TC");
    internalContracts[uint(ID.MR)] = master.getLatestAddress("MR");
    internalContracts[uint(ID.P1)] = master.getLatestAddress("P1");
    internalContracts[uint(ID.PS)] = master.getLatestAddress("PS");
    internalContracts[uint(ID.MC)] = master.getLatestAddress("MC");
  }

}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/*
    Copyright (C) 2020 NexusMutual.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

pragma solidity ^0.5.0;

import "./INXMMaster.sol";

contract MasterAware {

  INXMMaster public master;

  modifier onlyMember {
    require(master.isMember(msg.sender), "Caller is not a member");
    _;
  }

  modifier onlyInternal {
    require(master.isInternal(msg.sender), "Caller is not an internal contract");
    _;
  }

  modifier onlyMaster {
    if (address(master) != address(0)) {
      require(address(master) == msg.sender, "Not master");
    }
    _;
  }

  modifier onlyGovernance {
    require(
      master.checkIsAuthToGoverned(msg.sender),
      "Caller is not authorized to govern"
    );
    _;
  }

  modifier whenPaused {
    require(master.isPause(), "System is not paused");
    _;
  }

  modifier whenNotPaused {
    require(!master.isPause(), "System is paused");
    _;
  }

  function changeDependentContractAddress() external;

  function changeMasterAddress(address masterAddress) public onlyMaster {
    master = INXMMaster(masterAddress);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IPool {

  function transferAssetToSwapOperator(address asset, uint amount) external;

  function getAssetDetails(address _asset) external view returns (
    uint112 min,
    uint112 max,
    uint32 lastAssetSwapTime,
    uint maxSlippageRatio
  );

  function setAssetDataLastSwapTime(address asset, uint32 lastSwapTime) external;

  function minPoolEth() external returns (uint);
}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../../abstract/MasterAware.sol";
import "../capital/Pool.sol";
import "../claims/ClaimsReward.sol";
import "../claims/Incidents.sol";
import "../token/TokenController.sol";
import "../token/TokenData.sol";
import "./QuotationData.sol";

contract Quotation is MasterAware, ReentrancyGuard {
  using SafeMath for uint;

  ClaimsReward public cr;
  Pool public pool;
  IPooledStaking public pooledStaking;
  QuotationData public qd;
  TokenController public tc;
  TokenData public td;
  Incidents public incidents;

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public onlyInternal {
    cr = ClaimsReward(master.getLatestAddress("CR"));
    pool = Pool(master.getLatestAddress("P1"));
    pooledStaking = IPooledStaking(master.getLatestAddress("PS"));
    qd = QuotationData(master.getLatestAddress("QD"));
    tc = TokenController(master.getLatestAddress("TC"));
    td = TokenData(master.getLatestAddress("TD"));
    incidents = Incidents(master.getLatestAddress("IC"));
  }

  // solhint-disable-next-line no-empty-blocks
  function sendEther() public payable {}

  /**
   * @dev Expires a cover after a set period of time and changes the status of the cover
   * @dev Reduces the total and contract sum assured
   * @param coverId Cover Id.
   */
  function expireCover(uint coverId) external {

    uint expirationDate = qd.getValidityOfCover(coverId);
    require(expirationDate < now, "Quotation: cover is not due to expire");

    uint coverStatus = qd.getCoverStatusNo(coverId);
    require(coverStatus != uint(QuotationData.CoverStatus.CoverExpired), "Quotation: cover already expired");

    (/* claim count */, bool hasOpenClaim, /* accepted */) = tc.coverInfo(coverId);
    require(!hasOpenClaim, "Quotation: cover has an open claim");

    if (coverStatus != uint(QuotationData.CoverStatus.ClaimAccepted)) {
      (,, address contractAddress, bytes4 currency, uint amount,) = qd.getCoverDetailsByCoverID1(coverId);
      qd.subFromTotalSumAssured(currency, amount);
      qd.subFromTotalSumAssuredSC(contractAddress, currency, amount);
    }

    qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.CoverExpired));
  }

  function withdrawCoverNote(address coverOwner, uint[] calldata coverIds, uint[] calldata reasonIndexes) external {

    uint gracePeriod = tc.claimSubmissionGracePeriod();

    for (uint i = 0; i < coverIds.length; i++) {
      uint expirationDate = qd.getValidityOfCover(coverIds[i]);
      require(expirationDate.add(gracePeriod) < now, "Quotation: cannot withdraw before grace period expiration");
    }

    tc.withdrawCoverNote(coverOwner, coverIds, reasonIndexes);
  }

  function getWithdrawableCoverNoteCoverIds(
    address coverOwner
  ) public view returns (
    uint[] memory expiredCoverIds,
    bytes32[] memory lockReasons
  ) {

    uint[] memory coverIds = qd.getAllCoversOfUser(coverOwner);
    uint[] memory expiredIdsQueue = new uint[](coverIds.length);
    uint gracePeriod = tc.claimSubmissionGracePeriod();
    uint expiredQueueLength = 0;

    for (uint i = 0; i < coverIds.length; i++) {

      uint coverExpirationDate = qd.getValidityOfCover(coverIds[i]);
      uint gracePeriodExpirationDate = coverExpirationDate.add(gracePeriod);
      (/* claimCount */, bool hasOpenClaim, /* hasAcceptedClaim */) = tc.coverInfo(coverIds[i]);

      if (!hasOpenClaim && gracePeriodExpirationDate < now) {
        expiredIdsQueue[expiredQueueLength] = coverIds[i];
        expiredQueueLength++;
      }
    }

    expiredCoverIds = new uint[](expiredQueueLength);
    lockReasons = new bytes32[](expiredQueueLength);

    for (uint i = 0; i < expiredQueueLength; i++) {
      expiredCoverIds[i] = expiredIdsQueue[i];
      lockReasons[i] = keccak256(abi.encodePacked("CN", coverOwner, expiredIdsQueue[i]));
    }
  }

  function getWithdrawableCoverNotesAmount(address coverOwner) external view returns (uint) {

    uint withdrawableAmount;
    bytes32[] memory lockReasons;
    (/*expiredCoverIds*/, lockReasons) = getWithdrawableCoverNoteCoverIds(coverOwner);

    for (uint i = 0; i < lockReasons.length; i++) {
      uint coverNoteAmount = tc.tokensLocked(coverOwner, lockReasons[i]);
      withdrawableAmount = withdrawableAmount.add(coverNoteAmount);
    }

    return withdrawableAmount;
  }

  /**
   * @dev Makes Cover funded via NXM tokens.
   * @param smartCAdd Smart Contract Address
   */
  function makeCoverUsingNXMTokens(
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    bytes4 coverCurr,
    address smartCAdd,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external onlyMember whenNotPaused {
    tc.burnFrom(msg.sender, coverDetails[2]); // needs allowance
    _verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s, true);
  }

  /**
   * @dev Verifies cover details signed off chain.
   * @param from address of funder.
   * @param scAddress Smart Contract Address
   */
  function verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] memory coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public onlyInternal {
    _verifyCoverDetails(
      from,
      scAddress,
      coverCurr,
      coverDetails,
      coverPeriod,
      _v,
      _r,
      _s,
      false
    );
  }

  /**
   * @dev Verifies signature.
   * @param coverDetails details related to cover.
   * @param coverPeriod validity of cover.
   * @param contractAddress smart contract address.
   * @param _v argument from vrs hash.
   * @param _r argument from vrs hash.
   * @param _s argument from vrs hash.
   */
  function verifySignature(
    uint[] memory coverDetails,
    uint16 coverPeriod,
    bytes4 currency,
    address contractAddress,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public view returns (bool) {
    require(contractAddress != address(0));
    bytes32 hash = getOrderHash(coverDetails, coverPeriod, currency, contractAddress);
    return isValidSignature(hash, _v, _r, _s);
  }

  /**
   * @dev Gets order hash for given cover details.
   * @param coverDetails details realted to cover.
   * @param coverPeriod validity of cover.
   * @param contractAddress smart contract address.
   */
  function getOrderHash(
    uint[] memory coverDetails,
    uint16 coverPeriod,
    bytes4 currency,
    address contractAddress
  ) public view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        coverDetails[0],
        currency,
        coverPeriod,
        contractAddress,
        coverDetails[1],
        coverDetails[2],
        coverDetails[3],
        coverDetails[4],
        address(this)
      )
    );
  }

  /**
   * @dev Verifies signature.
   * @param hash order hash
   * @param v argument from vrs hash.
   * @param r argument from vrs hash.
   * @param s argument from vrs hash.
   */
  function isValidSignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
    address a = ecrecover(prefixedHash, v, r, s);
    return (a == qd.getAuthQuoteEngine());
  }

  /**
   * @dev Creates cover of the quotation, changes the status of the quotation ,
   * updates the total sum assured and locks the tokens of the cover against a quote.
   * @param from Quote member Ethereum address.
   */
  function _makeCover(//solhint-disable-line
    address payable from,
    address contractAddress,
    bytes4 coverCurrency,
    uint[] memory coverDetails,
    uint16 coverPeriod
  ) internal {

    address underlyingToken = incidents.underlyingToken(contractAddress);

    if (underlyingToken != address(0)) {
      address coverAsset = cr.getCurrencyAssetAddress(coverCurrency);
      require(coverAsset == underlyingToken, "Quotation: Unsupported cover asset for this product");
    }

    uint cid = qd.getCoverLength();

    qd.addCover(
      coverPeriod,
      coverDetails[0],
      from,
      coverCurrency,
      contractAddress,
      coverDetails[1],
      coverDetails[2]
    );

    uint coverNoteAmount = coverDetails[2].mul(qd.tokensRetained()).div(100);

    if (underlyingToken == address(0)) {
      uint gracePeriod = tc.claimSubmissionGracePeriod();
      uint claimSubmissionPeriod = uint(coverPeriod).mul(1 days).add(gracePeriod);
      bytes32 reason = keccak256(abi.encodePacked("CN", from, cid));

      // mint and lock cover note
      td.setDepositCNAmount(cid, coverNoteAmount);
      tc.mintCoverNote(from, reason, coverNoteAmount, claimSubmissionPeriod);
    } else {
      // minted directly to member's wallet
      tc.mint(from, coverNoteAmount);
    }

    qd.addInTotalSumAssured(coverCurrency, coverDetails[0]);
    qd.addInTotalSumAssuredSC(contractAddress, coverCurrency, coverDetails[0]);

    uint coverPremiumInNXM = coverDetails[2];
    uint stakersRewardPercentage = td.stakerCommissionPer();
    uint rewardValue = coverPremiumInNXM.mul(stakersRewardPercentage).div(100);
    pooledStaking.accumulateReward(contractAddress, rewardValue);
  }

  /**
   * @dev Makes a cover.
   * @param from address of funder.
   * @param scAddress Smart Contract Address
   */
  function _verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] memory coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    bool isNXM
  ) internal {

    require(coverDetails[3] > now, "Quotation: Quote has expired");
    require(coverPeriod >= 30 && coverPeriod <= 365, "Quotation: Cover period out of bounds");
    require(!qd.timestampRepeated(coverDetails[4]), "Quotation: Quote already used");
    qd.setTimestampRepeated(coverDetails[4]);

    address asset = cr.getCurrencyAssetAddress(coverCurr);
    if (coverCurr != "ETH" && !isNXM) {
      pool.transferAssetFrom(asset, from, coverDetails[1]);
    }

    require(verifySignature(coverDetails, coverPeriod, coverCurr, scAddress, _v, _r, _s), "Quotation: signature mismatch");
    _makeCover(from, scAddress, coverCurr, coverDetails, coverPeriod);
  }

  function createCover(
    address payable from,
    address scAddress,
    bytes4 currency,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external onlyInternal {

    require(coverDetails[3] > now, "Quotation: Quote has expired");
    require(coverPeriod >= 30 && coverPeriod <= 365, "Quotation: Cover period out of bounds");
    require(!qd.timestampRepeated(coverDetails[4]), "Quotation: Quote already used");
    qd.setTimestampRepeated(coverDetails[4]);

    require(verifySignature(coverDetails, coverPeriod, currency, scAddress, _v, _r, _s), "Quotation: signature mismatch");
    _makeCover(from, scAddress, currency, coverDetails, coverPeriod);
  }

  // referenced in master, keeping for now
  // solhint-disable-next-line no-empty-blocks
  function transferAssetsToNewContract(address) external pure {}

  function freeUpHeldCovers() external nonReentrant {

    IERC20 dai = IERC20(cr.getCurrencyAssetAddress("DAI"));
    uint membershipFee = td.joiningFee();
    uint lastCoverId = 106;

    for (uint id = 1; id <= lastCoverId; id++) {

      if (qd.holdedCoverIDStatus(id) != uint(QuotationData.HCIDStatus.kycPending)) {
        continue;
      }

      (/*id*/, /*sc*/, bytes4 currency, /*period*/) = qd.getHoldedCoverDetailsByID1(id);
      (/*id*/, address payable userAddress, uint[] memory coverDetails) = qd.getHoldedCoverDetailsByID2(id);

      uint refundedETH = membershipFee;
      uint coverPremium = coverDetails[1];

      if (qd.refundEligible(userAddress)) {
        qd.setRefundEligible(userAddress, false);
      }

      qd.setHoldedCoverIDStatus(id, uint(QuotationData.HCIDStatus.kycFailedOrRefunded));

      if (currency == "ETH") {
        refundedETH = refundedETH.add(coverPremium);
      } else {
        require(dai.transfer(userAddress, coverPremium), "Quotation: DAI refund transfer failed");
      }

      userAddress.transfer(refundedETH);
    }
  }
}

/* Copyright (C) 2020 NexusMutual.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface Aggregator {
  function latestAnswer() external view returns (int);
}

contract PriceFeedOracle {
  using SafeMath for uint;

  mapping(address => address) public aggregators;
  address public daiAddress;
  address public stETH;
  address constant public ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor (
    address _daiAggregator,
    address _daiAddress,
    address _stEthAddress
  ) public {
    aggregators[_daiAddress] = _daiAggregator;
    daiAddress = _daiAddress;
    stETH = _stEthAddress;
  }

  /**
   * @dev Returns the amount of ether in wei that are equivalent to 1 unit (10 ** decimals) of asset
   * @param asset quoted currency
   * @return price in ether
   */
  function getAssetToEthRate(address asset) public view returns (uint) {

    if (asset == ETH || asset == stETH) {
      return 1 ether;
    }

    address aggregatorAddress = aggregators[asset];

    if (aggregatorAddress == address(0)) {
      revert("PriceFeedOracle: Oracle asset not found");
    }

    int rate = Aggregator(aggregatorAddress).latestAnswer();
    require(rate > 0, "PriceFeedOracle: Rate must be > 0");

    return uint(rate);
  }

  /**
  * @dev Returns the amount of currency that is equivalent to ethIn amount of ether.
  * @param asset quoted  Supported values: ["DAI", "ETH"]
  * @param ethIn amount of ether to be converted to the currency
  * @return price in ether
  */
  function getAssetForEth(address asset, uint ethIn) external view returns (uint) {

    if (asset == daiAddress) {
      return ethIn.mul(1e18).div(getAssetToEthRate(daiAddress));
    }

    if (asset == ETH || asset == stETH) {
      return ethIn;
    }

    revert("PriceFeedOracle: Unknown asset");
  }

}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../abstract/MasterAware.sol";
import "../capital/Pool.sol";
import "../cover/QuotationData.sol";
import "../oracles/PriceFeedOracle.sol";
import "../token/NXMToken.sol";
import "../token/TokenData.sol";
import "./LegacyMCR.sol";

contract MCR is MasterAware {
  using SafeMath for uint;

  Pool public pool;
  QuotationData public qd;
  // sizeof(qd) + 96 = 160 + 96 = 256 (occupies entire slot)
  uint96 _unused;

  // the following values are expressed in basis points
  uint24 public mcrFloorIncrementThreshold = 13000;
  uint24 public maxMCRFloorIncrement = 100;
  uint24 public maxMCRIncrement = 500;
  uint24 public gearingFactor = 48000;
  // min update between MCR updates in seconds
  uint24 public minUpdateTime = 3600;
  uint112 public mcrFloor;

  uint112 public mcr;
  uint112 public desiredMCR;
  uint32 public lastUpdateTime;

  LegacyMCR public previousMCR;

  event MCRUpdated(
    uint mcr,
    uint desiredMCR,
    uint mcrFloor,
    uint mcrETHWithGear,
    uint totalSumAssured
  );

  uint constant UINT24_MAX = ~uint24(0);
  uint constant MAX_MCR_ADJUSTMENT = 100;
  uint constant BASIS_PRECISION = 10000;

  constructor (address masterAddress) public {
    changeMasterAddress(masterAddress);

    if (masterAddress != address(0)) {
      previousMCR = LegacyMCR(master.getLatestAddress("MC"));
    }
  }

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public {
    qd = QuotationData(master.getLatestAddress("QD"));
    pool = Pool(master.getLatestAddress("P1"));
    initialize();
  }

  function initialize() internal {

    address currentMCR = master.getLatestAddress("MC");

    if (address(previousMCR) == address(0) || currentMCR != address(this)) {
      // already initialized or not ready for initialization
      return;
    }

    // fetch MCR parameters from previous contract
    uint112 minCap = 7000 * 1e18;
    mcrFloor = uint112(previousMCR.variableMincap()) + minCap;
    mcr = uint112(previousMCR.getLastMCREther());
    desiredMCR = mcr;
    mcrFloorIncrementThreshold = uint24(previousMCR.dynamicMincapThresholdx100());
    maxMCRFloorIncrement = uint24(previousMCR.dynamicMincapIncrementx100());

    // set last updated time to now
    lastUpdateTime = uint32(block.timestamp);
    previousMCR = LegacyMCR(address(0));
  }

  /**
   * @dev Gets total sum assured (in ETH).
   * @return amount of sum assured
   */
  function getAllSumAssurance() public view returns (uint) {

    PriceFeedOracle priceFeed = pool.priceFeedOracle();
    address daiAddress = priceFeed.daiAddress();

    uint ethAmount = qd.getTotalSumAssured("ETH").mul(1e18);
    uint daiAmount = qd.getTotalSumAssured("DAI").mul(1e18);

    uint daiRate = priceFeed.getAssetToEthRate(daiAddress);
    uint daiAmountInEth = daiAmount.mul(daiRate).div(1e18);

    return ethAmount.add(daiAmountInEth);
  }

  /*
  * @dev trigger an MCR update. Current virtual MCR value is synced to storage, mcrFloor is potentially updated
  * and a new desiredMCR value to move towards is set.
  *
  */
  function updateMCR() public {
    _updateMCR(pool.getPoolValueInEth(), false);
  }

  function updateMCRInternal(uint poolValueInEth, bool forceUpdate) public onlyInternal {
    _updateMCR(poolValueInEth, forceUpdate);
  }

  function _updateMCR(uint poolValueInEth, bool forceUpdate) internal {

    // read with 1 SLOAD
    uint _mcrFloorIncrementThreshold = mcrFloorIncrementThreshold;
    uint _maxMCRFloorIncrement = maxMCRFloorIncrement;
    uint _gearingFactor = gearingFactor;
    uint _minUpdateTime = minUpdateTime;
    uint _mcrFloor =  mcrFloor;

    // read with 1 SLOAD
    uint112 _mcr = mcr;
    uint112 _desiredMCR = desiredMCR;
    uint32 _lastUpdateTime = lastUpdateTime;

    if (!forceUpdate && _lastUpdateTime + _minUpdateTime > block.timestamp) {
      return;
    }

    if (block.timestamp > _lastUpdateTime && pool.calculateMCRRatio(poolValueInEth, _mcr) >= _mcrFloorIncrementThreshold) {
        // MCR floor updates by up to maxMCRFloorIncrement percentage per day whenever the MCR ratio exceeds 1.3
        // MCR floor is monotonically increasing.
      uint basisPointsAdjustment = min(
        _maxMCRFloorIncrement.mul(block.timestamp - _lastUpdateTime).div(1 days),
        _maxMCRFloorIncrement
      );
      uint newMCRFloor = _mcrFloor.mul(basisPointsAdjustment.add(BASIS_PRECISION)).div(BASIS_PRECISION);
      require(newMCRFloor <= uint112(~0), 'MCR: newMCRFloor overflow');

      mcrFloor = uint112(newMCRFloor);
    }

    // sync the current virtual MCR value to storage
    uint112 newMCR = uint112(getMCR());
    if (newMCR != _mcr) {
      mcr = newMCR;
    }

    // the desiredMCR cannot fall below the mcrFloor but may have a higher or lower target value based
    // on the changes in the totalSumAssured in the system.
    uint totalSumAssured = getAllSumAssurance();
    uint gearedMCR = totalSumAssured.mul(BASIS_PRECISION).div(_gearingFactor);
    uint112 newDesiredMCR = uint112(max(gearedMCR, mcrFloor));
    if (newDesiredMCR != _desiredMCR) {
      desiredMCR = newDesiredMCR;
    }

    lastUpdateTime = uint32(block.timestamp);

    emit MCRUpdated(mcr, desiredMCR, mcrFloor, gearedMCR, totalSumAssured);
  }

  /**
   * @dev Calculates the current virtual MCR value. The virtual MCR value moves towards the desiredMCR value away
   * from the stored mcr value at constant velocity based on how much time passed from the lastUpdateTime.
   * The total change in virtual MCR cannot exceed 1% of stored mcr.
   *
   * This approach allows for the MCR to change smoothly across time without sudden jumps between values, while
   * always progressing towards the desiredMCR goal. The desiredMCR can change subject to the call of _updateMCR
   * so the virtual MCR value may change direction and start decreasing instead of increasing or vice-versa.
   *
   * @return mcr
   */
  function getMCR() public view returns (uint) {

    // read with 1 SLOAD
    uint _mcr = mcr;
    uint _desiredMCR = desiredMCR;
    uint _lastUpdateTime = lastUpdateTime;


    if (block.timestamp == _lastUpdateTime) {
      return _mcr;
    }

    uint _maxMCRIncrement = maxMCRIncrement;

    uint basisPointsAdjustment = _maxMCRIncrement.mul(block.timestamp - _lastUpdateTime).div(1 days);
    basisPointsAdjustment = min(basisPointsAdjustment, MAX_MCR_ADJUSTMENT);

    if (_desiredMCR > _mcr) {
      return min(_mcr.mul(basisPointsAdjustment.add(BASIS_PRECISION)).div(BASIS_PRECISION), _desiredMCR);
    }

    // in case desiredMCR <= mcr
    return max(_mcr.mul(BASIS_PRECISION - basisPointsAdjustment).div(BASIS_PRECISION), _desiredMCR);
  }

  function getGearedMCR() external view returns (uint) {
    return getAllSumAssurance().mul(BASIS_PRECISION).div(gearingFactor);
  }

  function min(uint x, uint y) pure internal returns (uint) {
    return x < y ? x : y;
  }

  function max(uint x, uint y) pure internal returns (uint) {
    return x > y ? x : y;
  }

  /**
   * @dev Updates Uint Parameters
   * @param code parameter code
   * @param val new value
   */
  function updateUintParameters(bytes8 code, uint val) public {
    require(master.checkIsAuthToGoverned(msg.sender));
    if (code == "DMCT") {

      require(val <= UINT24_MAX, "MCR: value too large");
      mcrFloorIncrementThreshold = uint24(val);

    } else if (code == "DMCI") {

      require(val <= UINT24_MAX, "MCR: value too large");
      maxMCRFloorIncrement = uint24(val);

    } else if (code == "MMIC") {

      require(val <= UINT24_MAX, "MCR: value too large");
      maxMCRIncrement = uint24(val);

    } else if (code == "GEAR") {

      require(val <= UINT24_MAX, "MCR: value too large");
      gearingFactor = uint24(val);

    } else if (code == "MUTI") {

      require(val <= UINT24_MAX, "MCR: value too large");
      minUpdateTime = uint24(val);

    } else {
      revert("Invalid param code");
    }
  }
}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

contract INXMMaster {

  address public tokenAddress;

  address public owner;

  uint public pauseTime;

  function delegateCallBack(bytes32 myid) external;

  function masterInitialized() public view returns (bool);

  function isInternal(address _add) public view returns (bool);

  function isPause() public view returns (bool check);

  function isOwner(address _add) public view returns (bool);

  function isMember(address _add) public view returns (bool);

  function checkIsAuthToGoverned(address _add) public view returns (bool);

  function updatePauseTime(uint _time) public;

  function dAppLocker() public view returns (address _add);

  function dAppToken() public view returns (address _add);

  function getLatestAddress(bytes2 _contractName) public view returns (address payable contractAddress);
}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../abstract/Iupgradable.sol";

contract TokenData is Iupgradable {
  using SafeMath for uint;

  address payable public walletAddress;
  uint public lockTokenTimeAfterCoverExp;
  uint public bookTime;
  uint public lockCADays;
  uint public lockMVDays;
  uint public scValidDays;
  uint public joiningFee;
  uint public stakerCommissionPer;
  uint public stakerMaxCommissionPer;
  uint public tokenExponent;
  uint public priceStep;

  struct StakeCommission {
    uint commissionEarned;
    uint commissionRedeemed;
  }

  struct Stake {
    address stakedContractAddress;
    uint stakedContractIndex;
    uint dateAdd;
    uint stakeAmount;
    uint unlockedAmount;
    uint burnedAmount;
    uint unLockableBeforeLastBurn;
  }

  struct Staker {
    address stakerAddress;
    uint stakerIndex;
  }

  struct CoverNote {
    uint amount;
    bool isDeposited;
  }

  /**
   * @dev mapping of uw address to array of sc address to fetch
   * all staked contract address of underwriter, pushing
   * data into this array of Stake returns stakerIndex
   */
  mapping(address => Stake[]) public stakerStakedContracts;

  /**
   * @dev mapping of sc address to array of UW address to fetch
   * all underwritters of the staked smart contract
   * pushing data into this mapped array returns scIndex
   */
  mapping(address => Staker[]) public stakedContractStakers;

  /**
   * @dev mapping of staked contract Address to the array of StakeCommission
   * here index of this array is stakedContractIndex
   */
  mapping(address => mapping(uint => StakeCommission)) public stakedContractStakeCommission;

  mapping(address => uint) public lastCompletedStakeCommission;

  /**
   * @dev mapping of the staked contract address to the current
   * staker index who will receive commission.
   */
  mapping(address => uint) public stakedContractCurrentCommissionIndex;

  /**
   * @dev mapping of the staked contract address to the
   * current staker index to burn token from.
   */
  mapping(address => uint) public stakedContractCurrentBurnIndex;

  /**
   * @dev mapping to return true if Cover Note deposited against coverId
   */
  mapping(uint => CoverNote) public depositedCN;

  mapping(address => uint) internal isBookedTokens;

  event Commission(
    address indexed stakedContractAddress,
    address indexed stakerAddress,
    uint indexed scIndex,
    uint commissionAmount
  );

  constructor(address payable _walletAdd) public {
    walletAddress = _walletAdd;
    bookTime = 12 hours;
    joiningFee = 2000000000000000; // 0.002 Ether
    lockTokenTimeAfterCoverExp = 35 days;
    scValidDays = 250;
    lockCADays = 7 days;
    lockMVDays = 2 days;
    stakerCommissionPer = 20;
    stakerMaxCommissionPer = 50;
    tokenExponent = 4;
    priceStep = 1000;
  }

  /**
   * @dev Change the wallet address which receive Joining Fee
   */
  function changeWalletAddress(address payable _address) external onlyInternal {
    walletAddress = _address;
  }

  /**
   * @dev Gets Uint Parameters of a code
   * @param code whose details we want
   * @return string value of the code
   * @return associated amount (time or perc or value) to the code
   */
  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {
    codeVal = code;
    if (code == "TOKEXP") {

      val = tokenExponent;

    } else if (code == "TOKSTEP") {

      val = priceStep;

    } else if (code == "RALOCKT") {

      val = scValidDays;

    } else if (code == "RACOMM") {

      val = stakerCommissionPer;

    } else if (code == "RAMAXC") {

      val = stakerMaxCommissionPer;

    } else if (code == "CABOOKT") {

      val = bookTime / (1 hours);

    } else if (code == "CALOCKT") {

      val = lockCADays / (1 days);

    } else if (code == "MVLOCKT") {

      val = lockMVDays / (1 days);

    } else if (code == "QUOLOCKT") {

      val = lockTokenTimeAfterCoverExp / (1 days);

    } else if (code == "JOINFEE") {

      val = joiningFee;

    }
  }

  /**
  * @dev Just for interface
  */
  function changeDependentContractAddress() public {//solhint-disable-line
  }

  /**
   * @dev to get the contract staked by a staker
   * @param _stakerAddress is the address of the staker
   * @param _stakerIndex is the index of staker
   * @return the address of staked contract
   */
  function getStakerStakedContractByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  public
  view
  returns (address stakedContractAddress)
  {
    stakedContractAddress = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakedContractAddress;
  }

  /**
   * @dev to get the staker's staked burned
   * @param _stakerAddress is the address of the staker
   * @param _stakerIndex is the index of staker
   * @return amount burned
   */
  function getStakerStakedBurnedByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  public
  view
  returns (uint burnedAmount)
  {
    burnedAmount = stakerStakedContracts[
    _stakerAddress][_stakerIndex].burnedAmount;
  }

  /**
   * @dev to get the staker's staked unlockable before the last burn
   * @param _stakerAddress is the address of the staker
   * @param _stakerIndex is the index of staker
   * @return unlockable staked tokens
   */
  function getStakerStakedUnlockableBeforeLastBurnByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  public
  view
  returns (uint unlockable)
  {
    unlockable = stakerStakedContracts[
    _stakerAddress][_stakerIndex].unLockableBeforeLastBurn;
  }

  /**
   * @dev to get the staker's staked contract index
   * @param _stakerAddress is the address of the staker
   * @param _stakerIndex is the index of staker
   * @return is the index of the smart contract address
   */
  function getStakerStakedContractIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  public
  view
  returns (uint scIndex)
  {
    scIndex = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakedContractIndex;
  }

  /**
   * @dev to get the staker index of the staked contract
   * @param _stakedContractAddress is the address of the staked contract
   * @param _stakedContractIndex is the index of staked contract
   * @return is the index of the staker
   */
  function getStakedContractStakerIndex(
    address _stakedContractAddress,
    uint _stakedContractIndex
  )
  public
  view
  returns (uint sIndex)
  {
    sIndex = stakedContractStakers[
    _stakedContractAddress][_stakedContractIndex].stakerIndex;
  }

  /**
   * @dev to get the staker's initial staked amount on the contract
   * @param _stakerAddress is the address of the staker
   * @param _stakerIndex is the index of staker
   * @return staked amount
   */
  function getStakerInitialStakedAmountOnContract(
    address _stakerAddress,
    uint _stakerIndex
  )
  public
  view
  returns (uint amount)
  {
    amount = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakeAmount;
  }

  /**
   * @dev to get the staker's staked contract length
   * @param _stakerAddress is the address of the staker
   * @return length of staked contract
   */
  function getStakerStakedContractLength(
    address _stakerAddress
  )
  public
  view
  returns (uint length)
  {
    length = stakerStakedContracts[_stakerAddress].length;
  }

  /**
   * @dev to get the staker's unlocked tokens which were staked
   * @param _stakerAddress is the address of the staker
   * @param _stakerIndex is the index of staker
   * @return amount
   */
  function getStakerUnlockedStakedTokens(
    address _stakerAddress,
    uint _stakerIndex
  )
  public
  view
  returns (uint amount)
  {
    amount = stakerStakedContracts[
    _stakerAddress][_stakerIndex].unlockedAmount;
  }

  /**
   * @dev pushes the unlocked staked tokens by a staker.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker to distribute commission.
   * @param _amount amount to be given as commission.
   */
  function pushUnlockedStakedTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  )
  public
  onlyInternal
  {
    stakerStakedContracts[_stakerAddress][
    _stakerIndex].unlockedAmount = stakerStakedContracts[_stakerAddress][
    _stakerIndex].unlockedAmount.add(_amount);
  }

  /**
   * @dev pushes the Burned tokens for a staker.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker.
   * @param _amount amount to be burned.
   */
  function pushBurnedTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  )
  public
  onlyInternal
  {
    stakerStakedContracts[_stakerAddress][
    _stakerIndex].burnedAmount = stakerStakedContracts[_stakerAddress][
    _stakerIndex].burnedAmount.add(_amount);
  }

  /**
   * @dev pushes the unLockable tokens for a staker before last burn.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker.
   * @param _amount amount to be added to unlockable.
   */
  function pushUnlockableBeforeLastBurnTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  )
  public
  onlyInternal
  {
    stakerStakedContracts[_stakerAddress][
    _stakerIndex].unLockableBeforeLastBurn = stakerStakedContracts[_stakerAddress][
    _stakerIndex].unLockableBeforeLastBurn.add(_amount);
  }

  /**
   * @dev sets the unLockable tokens for a staker before last burn.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker.
   * @param _amount amount to be added to unlockable.
   */
  function setUnlockableBeforeLastBurnTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  )
  public
  onlyInternal
  {
    stakerStakedContracts[_stakerAddress][
    _stakerIndex].unLockableBeforeLastBurn = _amount;
  }

  /**
   * @dev pushes the earned commission earned by a staker.
   * @param _stakerAddress address of staker.
   * @param _stakedContractAddress address of smart contract.
   * @param _stakedContractIndex index of the staker to distribute commission.
   * @param _commissionAmount amount to be given as commission.
   */
  function pushEarnedStakeCommissions(
    address _stakerAddress,
    address _stakedContractAddress,
    uint _stakedContractIndex,
    uint _commissionAmount
  )
  public
  onlyInternal
  {
    stakedContractStakeCommission[_stakedContractAddress][_stakedContractIndex].
    commissionEarned = stakedContractStakeCommission[_stakedContractAddress][
    _stakedContractIndex].commissionEarned.add(_commissionAmount);

    emit Commission(
      _stakerAddress,
      _stakedContractAddress,
      _stakedContractIndex,
      _commissionAmount
    );
  }

  /**
   * @dev pushes the redeemed commission redeemed by a staker.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker to distribute commission.
   * @param _amount amount to be given as commission.
   */
  function pushRedeemedStakeCommissions(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  )
  public
  onlyInternal
  {
    uint stakedContractIndex = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakedContractIndex;
    address stakedContractAddress = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakedContractAddress;
    stakedContractStakeCommission[stakedContractAddress][stakedContractIndex].
    commissionRedeemed = stakedContractStakeCommission[
    stakedContractAddress][stakedContractIndex].commissionRedeemed.add(_amount);
  }

  /**
   * @dev Gets stake commission given to an underwriter
   * for particular stakedcontract on given index.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker commission.
   */
  function getStakerEarnedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  public
  view
  returns (uint)
  {
    return _getStakerEarnedStakeCommission(_stakerAddress, _stakerIndex);
  }

  /**
   * @dev Gets stake commission redeemed by an underwriter
   * for particular staked contract on given index.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker commission.
   * @return commissionEarned total amount given to staker.
   */
  function getStakerRedeemedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  public
  view
  returns (uint)
  {
    return _getStakerRedeemedStakeCommission(_stakerAddress, _stakerIndex);
  }

  /**
   * @dev Gets total stake commission given to an underwriter
   * @param _stakerAddress address of staker.
   * @return totalCommissionEarned total commission earned by staker.
   */
  function getStakerTotalEarnedStakeCommission(
    address _stakerAddress
  )
  public
  view
  returns (uint totalCommissionEarned)
  {
    totalCommissionEarned = 0;
    for (uint i = 0; i < stakerStakedContracts[_stakerAddress].length; i++) {
      totalCommissionEarned = totalCommissionEarned.
      add(_getStakerEarnedStakeCommission(_stakerAddress, i));
    }
  }

  /**
   * @dev Gets total stake commission given to an underwriter
   * @param _stakerAddress address of staker.
   * @return totalCommissionEarned total commission earned by staker.
   */
  function getStakerTotalReedmedStakeCommission(
    address _stakerAddress
  )
  public
  view
  returns (uint totalCommissionRedeemed)
  {
    totalCommissionRedeemed = 0;
    for (uint i = 0; i < stakerStakedContracts[_stakerAddress].length; i++) {
      totalCommissionRedeemed = totalCommissionRedeemed.add(
        _getStakerRedeemedStakeCommission(_stakerAddress, i));
    }
  }

  /**
   * @dev set flag to deposit/ undeposit cover note
   * against a cover Id
   * @param coverId coverId of Cover
   * @param flag true/false for deposit/undeposit
   */
  function setDepositCN(uint coverId, bool flag) public onlyInternal {

    if (flag == true) {
      require(!depositedCN[coverId].isDeposited, "Cover note already deposited");
    }

    depositedCN[coverId].isDeposited = flag;
  }

  /**
   * @dev set locked cover note amount
   * against a cover Id
   * @param coverId coverId of Cover
   * @param amount amount of nxm to be locked
   */
  function setDepositCNAmount(uint coverId, uint amount) public onlyInternal {

    depositedCN[coverId].amount = amount;
  }

  /**
   * @dev to get the staker address on a staked contract
   * @param _stakedContractAddress is the address of the staked contract in concern
   * @param _stakedContractIndex is the index of staked contract's index
   * @return address of staker
   */
  function getStakedContractStakerByIndex(
    address _stakedContractAddress,
    uint _stakedContractIndex
  )
  public
  view
  returns (address stakerAddress)
  {
    stakerAddress = stakedContractStakers[
    _stakedContractAddress][_stakedContractIndex].stakerAddress;
  }

  /**
   * @dev to get the length of stakers on a staked contract
   * @param _stakedContractAddress is the address of the staked contract in concern
   * @return length in concern
   */
  function getStakedContractStakersLength(
    address _stakedContractAddress
  )
  public
  view
  returns (uint length)
  {
    length = stakedContractStakers[_stakedContractAddress].length;
  }

  /**
   * @dev Adds a new stake record.
   * @param _stakerAddress staker address.
   * @param _stakedContractAddress smart contract address.
   * @param _amount amountof NXM to be staked.
   */
  function addStake(
    address _stakerAddress,
    address _stakedContractAddress,
    uint _amount
  )
  public
  onlyInternal
  returns (uint scIndex)
  {
    scIndex = (stakedContractStakers[_stakedContractAddress].push(
      Staker(_stakerAddress, stakerStakedContracts[_stakerAddress].length))).sub(1);
    stakerStakedContracts[_stakerAddress].push(
      Stake(_stakedContractAddress, scIndex, now, _amount, 0, 0, 0));
  }

  /**
   * @dev books the user's tokens for maintaining Assessor Velocity,
   * i.e. once a token is used to cast a vote as a Claims assessor,
   * @param _of user's address.
   */
  function bookCATokens(address _of) public onlyInternal {
    require(!isCATokensBooked(_of), "Tokens already booked");
    isBookedTokens[_of] = now.add(bookTime);
  }

  /**
   * @dev to know if claim assessor's tokens are booked or not
   * @param _of is the claim assessor's address in concern
   * @return boolean representing the status of tokens booked
   */
  function isCATokensBooked(address _of) public view returns (bool res) {
    if (now < isBookedTokens[_of])
      res = true;
  }

  /**
   * @dev Sets the index which will receive commission.
   * @param _stakedContractAddress smart contract address.
   * @param _index current index.
   */
  function setStakedContractCurrentCommissionIndex(
    address _stakedContractAddress,
    uint _index
  )
  public
  onlyInternal
  {
    stakedContractCurrentCommissionIndex[_stakedContractAddress] = _index;
  }

  /**
   * @dev Sets the last complete commission index
   * @param _stakerAddress smart contract address.
   * @param _index current index.
   */
  function setLastCompletedStakeCommissionIndex(
    address _stakerAddress,
    uint _index
  )
  public
  onlyInternal
  {
    lastCompletedStakeCommission[_stakerAddress] = _index;
  }

  /**
   * @dev Sets the index till which commission is distrubuted.
   * @param _stakedContractAddress smart contract address.
   * @param _index current index.
   */
  function setStakedContractCurrentBurnIndex(
    address _stakedContractAddress,
    uint _index
  )
  public
  onlyInternal
  {
    stakedContractCurrentBurnIndex[_stakedContractAddress] = _index;
  }

  /**
   * @dev Updates Uint Parameters of a code
   * @param code whose details we want to update
   * @param val value to set
   */
  function updateUintParameters(bytes8 code, uint val) public {
    require(ms.checkIsAuthToGoverned(msg.sender));
    if (code == "TOKEXP") {

      _setTokenExponent(val);

    } else if (code == "TOKSTEP") {

      _setPriceStep(val);

    } else if (code == "RALOCKT") {

      _changeSCValidDays(val);

    } else if (code == "RACOMM") {

      _setStakerCommissionPer(val);

    } else if (code == "RAMAXC") {

      _setStakerMaxCommissionPer(val);

    } else if (code == "CABOOKT") {

      _changeBookTime(val * 1 hours);

    } else if (code == "CALOCKT") {

      _changelockCADays(val * 1 days);

    } else if (code == "MVLOCKT") {

      _changelockMVDays(val * 1 days);

    } else if (code == "QUOLOCKT") {

      _setLockTokenTimeAfterCoverExp(val * 1 days);

    } else if (code == "JOINFEE") {

      _setJoiningFee(val);

    } else {
      revert("Invalid param code");
    }
  }

  /**
   * @dev Internal function to get stake commission given to an
   * underwriter for particular stakedcontract on given index.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker commission.
   */
  function _getStakerEarnedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  internal
  view
  returns (uint amount)
  {
    uint _stakedContractIndex;
    address _stakedContractAddress;
    _stakedContractAddress = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakedContractAddress;
    _stakedContractIndex = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakedContractIndex;
    amount = stakedContractStakeCommission[
    _stakedContractAddress][_stakedContractIndex].commissionEarned;
  }

  /**
   * @dev Internal function to get stake commission redeemed by an
   * underwriter for particular stakedcontract on given index.
   * @param _stakerAddress address of staker.
   * @param _stakerIndex index of the staker commission.
   */
  function _getStakerRedeemedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  internal
  view
  returns (uint amount)
  {
    uint _stakedContractIndex;
    address _stakedContractAddress;
    _stakedContractAddress = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakedContractAddress;
    _stakedContractIndex = stakerStakedContracts[
    _stakerAddress][_stakerIndex].stakedContractIndex;
    amount = stakedContractStakeCommission[
    _stakedContractAddress][_stakedContractIndex].commissionRedeemed;
  }

  /**
   * @dev to set the percentage of staker commission
   * @param _val is new percentage value
   */
  function _setStakerCommissionPer(uint _val) internal {
    stakerCommissionPer = _val;
  }

  /**
   * @dev to set the max percentage of staker commission
   * @param _val is new percentage value
   */
  function _setStakerMaxCommissionPer(uint _val) internal {
    stakerMaxCommissionPer = _val;
  }

  /**
   * @dev to set the token exponent value
   * @param _val is new value
   */
  function _setTokenExponent(uint _val) internal {
    tokenExponent = _val;
  }

  /**
   * @dev to set the price step
   * @param _val is new value
   */
  function _setPriceStep(uint _val) internal {
    priceStep = _val;
  }

  /**
   * @dev Changes number of days for which NXM needs to staked in case of underwriting
   */
  function _changeSCValidDays(uint _days) internal {
    scValidDays = _days;
  }

  /**
   * @dev Changes the time period up to which tokens will be locked.
   *      Used to generate the validity period of tokens booked by
   *      a user for participating in claim's assessment/claim's voting.
   */
  function _changeBookTime(uint _time) internal {
    bookTime = _time;
  }

  /**
   * @dev Changes lock CA days - number of days for which tokens
   * are locked while submitting a vote.
   */
  function _changelockCADays(uint _val) internal {
    lockCADays = _val;
  }

  /**
   * @dev Changes lock MV days - number of days for which tokens are locked
   * while submitting a vote.
   */
  function _changelockMVDays(uint _val) internal {
    lockMVDays = _val;
  }

  /**
   * @dev Changes extra lock period for a cover, post its expiry.
   */
  function _setLockTokenTimeAfterCoverExp(uint time) internal {
    lockTokenTimeAfterCoverExp = time;
  }

  /**
   * @dev Set the joining fee for membership
   */
  function _setJoiningFee(uint _amount) internal {
    joiningFee = _amount;
  }
}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../abstract/Iupgradable.sol";

contract QuotationData is Iupgradable {
  using SafeMath for uint;

  enum HCIDStatus {NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover}

  enum CoverStatus {Active, ClaimAccepted, ClaimDenied, CoverExpired, ClaimSubmitted, Requested}

  struct Cover {
    address payable memberAddress;
    bytes4 currencyCode;
    uint sumAssured;
    uint16 coverPeriod;
    uint validUntil;
    address scAddress;
    uint premiumNXM;
  }

  struct HoldCover {
    uint holdCoverId;
    address payable userAddress;
    address scAddress;
    bytes4 coverCurr;
    uint[] coverDetails;
    uint16 coverPeriod;
  }

  address public authQuoteEngine;

  mapping(bytes4 => uint) internal currencyCSA;
  mapping(address => uint[]) internal userCover;
  mapping(address => uint[]) public userHoldedCover;
  mapping(address => bool) public refundEligible;
  mapping(address => mapping(bytes4 => uint)) internal currencyCSAOfSCAdd;
  mapping(uint => uint8) public coverStatus;
  mapping(uint => uint) public holdedCoverIDStatus;
  mapping(uint => bool) public timestampRepeated;


  Cover[] internal allCovers;
  HoldCover[] internal allCoverHolded;

  uint public stlp;
  uint public stl;
  uint public pm;
  uint public minDays;
  uint public tokensRetained;
  address public kycAuthAddress;

  event CoverDetailsEvent(
    uint indexed cid,
    address scAdd,
    uint sumAssured,
    uint expiry,
    uint premium,
    uint premiumNXM,
    bytes4 curr
  );

  event CoverStatusEvent(uint indexed cid, uint8 statusNum);

  constructor(address _authQuoteAdd, address _kycAuthAdd) public {
    authQuoteEngine = _authQuoteAdd;
    kycAuthAddress = _kycAuthAdd;
    stlp = 90;
    stl = 100;
    pm = 30;
    minDays = 30;
    tokensRetained = 10;
    allCovers.push(Cover(address(0), "0x00", 0, 0, 0, address(0), 0));
    uint[] memory arr = new uint[](1);
    allCoverHolded.push(HoldCover(0, address(0), address(0), 0x00, arr, 0));

  }

  /// @dev Adds the amount in Total Sum Assured of a given currency of a given smart contract address.
  /// @param _add Smart Contract Address.
  /// @param _amount Amount to be added.
  function addInTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external onlyInternal {
    currencyCSAOfSCAdd[_add][_curr] = currencyCSAOfSCAdd[_add][_curr].add(_amount);
  }

  /// @dev Subtracts the amount from Total Sum Assured of a given currency and smart contract address.
  /// @param _add Smart Contract Address.
  /// @param _amount Amount to be subtracted.
  function subFromTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external onlyInternal {
    currencyCSAOfSCAdd[_add][_curr] = currencyCSAOfSCAdd[_add][_curr].sub(_amount);
  }

  /// @dev Subtracts the amount from Total Sum Assured of a given currency.
  /// @param _curr Currency Name.
  /// @param _amount Amount to be subtracted.
  function subFromTotalSumAssured(bytes4 _curr, uint _amount) external onlyInternal {
    currencyCSA[_curr] = currencyCSA[_curr].sub(_amount);
  }

  /// @dev Adds the amount in Total Sum Assured of a given currency.
  /// @param _curr Currency Name.
  /// @param _amount Amount to be added.
  function addInTotalSumAssured(bytes4 _curr, uint _amount) external onlyInternal {
    currencyCSA[_curr] = currencyCSA[_curr].add(_amount);
  }

  /// @dev sets bit for timestamp to avoid replay attacks.
  function setTimestampRepeated(uint _timestamp) external onlyInternal {
    timestampRepeated[_timestamp] = true;
  }

  /// @dev Creates a blank new cover.
  function addCover(
    uint16 _coverPeriod,
    uint _sumAssured,
    address payable _userAddress,
    bytes4 _currencyCode,
    address _scAddress,
    uint premium,
    uint premiumNXM
  )
  external
  onlyInternal
  {
    uint expiryDate = now.add(uint(_coverPeriod).mul(1 days));
    allCovers.push(Cover(_userAddress, _currencyCode,
      _sumAssured, _coverPeriod, expiryDate, _scAddress, premiumNXM));
    uint cid = allCovers.length.sub(1);
    userCover[_userAddress].push(cid);
    emit CoverDetailsEvent(cid, _scAddress, _sumAssured, expiryDate, premium, premiumNXM, _currencyCode);
  }

  /// @dev create holded cover which will process after verdict of KYC.
  function addHoldCover(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] calldata coverDetails,
    uint16 coverPeriod
  )
  external
  onlyInternal
  {
    uint holdedCoverLen = allCoverHolded.length;
    holdedCoverIDStatus[holdedCoverLen] = uint(HCIDStatus.kycPending);
    allCoverHolded.push(HoldCover(holdedCoverLen, from, scAddress,
      coverCurr, coverDetails, coverPeriod));
    userHoldedCover[from].push(allCoverHolded.length.sub(1));

  }

  ///@dev sets refund eligible bit.
  ///@param _add user address.
  ///@param status indicates if user have pending kyc.
  function setRefundEligible(address _add, bool status) external onlyInternal {
    refundEligible[_add] = status;
  }

  /// @dev to set current status of particular holded coverID (1 for not completed KYC,
  /// 2 for KYC passed, 3 for failed KYC or full refunded,
  /// 4 for KYC completed but cover not processed)
  function setHoldedCoverIDStatus(uint holdedCoverID, uint status) external onlyInternal {
    holdedCoverIDStatus[holdedCoverID] = status;
  }

  /**
   * @dev to set address of kyc authentication
   * @param _add is the new address
   */
  function setKycAuthAddress(address _add) external onlyInternal {
    kycAuthAddress = _add;
  }

  /// @dev Changes authorised address for generating quote off chain.
  function changeAuthQuoteEngine(address _add) external onlyInternal {
    authQuoteEngine = _add;
  }

  /**
   * @dev Gets Uint Parameters of a code
   * @param code whose details we want
   * @return string value of the code
   * @return associated amount (time or perc or value) to the code
   */
  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {
    codeVal = code;

    if (code == "STLP") {
      val = stlp;

    } else if (code == "STL") {

      val = stl;

    } else if (code == "PM") {

      val = pm;

    } else if (code == "QUOMIND") {

      val = minDays;

    } else if (code == "QUOTOK") {

      val = tokensRetained;

    }

  }

  /// @dev Gets Product details.
  /// @return  _minDays minimum cover period.
  /// @return  _PM Profit margin.
  /// @return  _STL short term Load.
  /// @return  _STLP short term load period.
  function getProductDetails()
  external
  view
  returns (
    uint _minDays,
    uint _pm,
    uint _stl,
    uint _stlp
  )
  {

    _minDays = minDays;
    _pm = pm;
    _stl = stl;
    _stlp = stlp;
  }

  /// @dev Gets total number covers created till date.
  function getCoverLength() external view returns (uint len) {
    return (allCovers.length);
  }

  /// @dev Gets Authorised Engine address.
  function getAuthQuoteEngine() external view returns (address _add) {
    _add = authQuoteEngine;
  }

  /// @dev Gets the Total Sum Assured amount of a given currency.
  function getTotalSumAssured(bytes4 _curr) external view returns (uint amount) {
    amount = currencyCSA[_curr];
  }

  /// @dev Gets all the Cover ids generated by a given address.
  /// @param _add User's address.
  /// @return allCover array of covers.
  function getAllCoversOfUser(address _add) external view returns (uint[] memory allCover) {
    return (userCover[_add]);
  }

  /// @dev Gets total number of covers generated by a given address
  function getUserCoverLength(address _add) external view returns (uint len) {
    len = userCover[_add].length;
  }

  /// @dev Gets the status of a given cover.
  function getCoverStatusNo(uint _cid) external view returns (uint8) {
    return coverStatus[_cid];
  }

  /// @dev Gets the Cover Period (in days) of a given cover.
  function getCoverPeriod(uint _cid) external view returns (uint32 cp) {
    cp = allCovers[_cid].coverPeriod;
  }

  /// @dev Gets the Sum Assured Amount of a given cover.
  function getCoverSumAssured(uint _cid) external view returns (uint sa) {
    sa = allCovers[_cid].sumAssured;
  }

  /// @dev Gets the Currency Name in which a given cover is assured.
  function getCurrencyOfCover(uint _cid) external view returns (bytes4 curr) {
    curr = allCovers[_cid].currencyCode;
  }

  /// @dev Gets the validity date (timestamp) of a given cover.
  function getValidityOfCover(uint _cid) external view returns (uint date) {
    date = allCovers[_cid].validUntil;
  }

  /// @dev Gets Smart contract address of cover.
  function getscAddressOfCover(uint _cid) external view returns (uint, address) {
    return (_cid, allCovers[_cid].scAddress);
  }

  /// @dev Gets the owner address of a given cover.
  function getCoverMemberAddress(uint _cid) external view returns (address payable _add) {
    _add = allCovers[_cid].memberAddress;
  }

  /// @dev Gets the premium amount of a given cover in NXM.
  function getCoverPremiumNXM(uint _cid) external view returns (uint _premiumNXM) {
    _premiumNXM = allCovers[_cid].premiumNXM;
  }

  /// @dev Provides the details of a cover Id
  /// @param _cid cover Id
  /// @return memberAddress cover user address.
  /// @return scAddress smart contract Address
  /// @return currencyCode currency of cover
  /// @return sumAssured sum assured of cover
  /// @return premiumNXM premium in NXM
  function getCoverDetailsByCoverID1(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    address _memberAddress,
    address _scAddress,
    bytes4 _currencyCode,
    uint _sumAssured,
    uint premiumNXM
  )
  {
    return (
    _cid,
    allCovers[_cid].memberAddress,
    allCovers[_cid].scAddress,
    allCovers[_cid].currencyCode,
    allCovers[_cid].sumAssured,
    allCovers[_cid].premiumNXM
    );
  }

  /// @dev Provides details of a cover Id
  /// @param _cid cover Id
  /// @return status status of cover.
  /// @return sumAssured Sum assurance of cover.
  /// @return coverPeriod Cover Period of cover (in days).
  /// @return validUntil is validity of cover.
  function getCoverDetailsByCoverID2(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil
  )
  {

    return (
    _cid,
    coverStatus[_cid],
    allCovers[_cid].sumAssured,
    allCovers[_cid].coverPeriod,
    allCovers[_cid].validUntil
    );
  }

  /// @dev Provides details of a holded cover Id
  /// @param _hcid holded cover Id
  /// @return scAddress SmartCover address of cover.
  /// @return coverCurr currency of cover.
  /// @return coverPeriod Cover Period of cover (in days).
  function getHoldedCoverDetailsByID1(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address scAddress,
    bytes4 coverCurr,
    uint16 coverPeriod
  )
  {
    return (
    _hcid,
    allCoverHolded[_hcid].scAddress,
    allCoverHolded[_hcid].coverCurr,
    allCoverHolded[_hcid].coverPeriod
    );
  }

  /// @dev Gets total number holded covers created till date.
  function getUserHoldedCoverLength(address _add) external view returns (uint) {
    return userHoldedCover[_add].length;
  }

  /// @dev Gets holded cover index by index of user holded covers.
  function getUserHoldedCoverByIndex(address _add, uint index) external view returns (uint) {
    return userHoldedCover[_add][index];
  }

  /// @dev Provides the details of a holded cover Id
  /// @param _hcid holded cover Id
  /// @return memberAddress holded cover user address.
  /// @return coverDetails array contains SA, Cover Currency Price,Price in NXM, Expiration time of Qoute.
  function getHoldedCoverDetailsByID2(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address payable memberAddress,
    uint[] memory coverDetails
  )
  {
    return (
    _hcid,
    allCoverHolded[_hcid].userAddress,
    allCoverHolded[_hcid].coverDetails
    );
  }

  /// @dev Gets the Total Sum Assured amount of a given currency and smart contract address.
  function getTotalSumAssuredSC(address _add, bytes4 _curr) external view returns (uint amount) {
    amount = currencyCSAOfSCAdd[_add][_curr];
  }

  //solhint-disable-next-line
  function changeDependentContractAddress() public {}

  /// @dev Changes the status of a given cover.
  /// @param _cid cover Id.
  /// @param _stat New status.
  function changeCoverStatusNo(uint _cid, uint8 _stat) public onlyInternal {
    coverStatus[_cid] = _stat;
    emit CoverStatusEvent(_cid, _stat);
  }

  /**
   * @dev Updates Uint Parameters of a code
   * @param code whose details we want to update
   * @param val value to set
   */
  function updateUintParameters(bytes8 code, uint val) public {

    require(ms.checkIsAuthToGoverned(msg.sender));
    if (code == "STLP") {
      _changeSTLP(val);

    } else if (code == "STL") {

      _changeSTL(val);

    } else if (code == "PM") {

      _changePM(val);

    } else if (code == "QUOMIND") {

      _changeMinDays(val);

    } else if (code == "QUOTOK") {

      _setTokensRetained(val);

    } else {

      revert("Invalid param code");
    }

  }

  /// @dev Changes the existing Profit Margin value
  function _changePM(uint _pm) internal {
    pm = _pm;
  }

  /// @dev Changes the existing Short Term Load Period (STLP) value.
  function _changeSTLP(uint _stlp) internal {
    stlp = _stlp;
  }

  /// @dev Changes the existing Short Term Load (STL) value.
  function _changeSTL(uint _stl) internal {
    stl = _stl;
  }

  /// @dev Changes the existing Minimum cover period (in days)
  function _changeMinDays(uint _days) internal {
    minDays = _days;
  }

  /**
   * @dev to set the the amount of tokens retained
   * @param val is the amount retained
   */
  function _setTokensRetained(uint val) internal {
    tokensRetained = val;
  }
}

pragma solidity ^0.5.0;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface OZIERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
  external returns (bool);

  function transferFrom(address from, address to, uint256 value)
  external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
  external view returns (uint256);

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

pragma solidity ^0.5.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library OZSafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
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
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

pragma solidity ^0.5.0;

import "./INXMMaster.sol";

contract Iupgradable {

  INXMMaster public ms;
  address public nxMasterAddress;

  modifier onlyInternal {
    require(ms.isInternal(msg.sender));
    _;
  }

  modifier isMemberAndcheckPause {
    require(ms.isPause() == false && ms.isMember(msg.sender) == true);
    _;
  }

  modifier onlyOwner {
    require(ms.isOwner(msg.sender));
    _;
  }

  modifier checkPause {
    require(ms.isPause() == false);
    _;
  }

  modifier isMember {
    require(ms.isMember(msg.sender), "Not member");
    _;
  }

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public;

  /**
   * @dev change master address
   * @param _masterAddress is the new address
   */
  function changeMasterAddress(address _masterAddress) public {
    if (address(ms) != address(0)) {
      require(address(ms) == msg.sender, "Not master");
    }

    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;
  }

}

pragma solidity ^0.5.0;


interface IPooledStaking {

  function accumulateReward(address contractAddress, uint amount) external;

  function pushBurn(address contractAddress, uint amount) external;

  function hasPendingActions() external view returns (bool);

  function processPendingActions(uint maxIterations) external returns (bool finished);

  function contractStake(address contractAddress) external view returns (uint);

  function stakerReward(address staker) external view returns (uint);

  function stakerDeposit(address staker) external view returns (uint);

  function stakerContractStake(address staker, address contractAddress) external view returns (uint);

  function withdraw(uint amount) external;

  function stakerMaxWithdrawable(address stakerAddress) external view returns (uint);

  function withdrawReward(address stakerAddress) external;
}

pragma solidity ^0.5.0;

/**
 * @title ERC1132 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1132
 */

contract LockHandler {
  /**
   * @dev Reasons why a user's tokens have been locked
   */
  mapping(address => bytes32[]) public lockReason;

  /**
   * @dev locked token structure
   */
  struct LockToken {
    uint256 amount;
    uint256 validity;
    bool claimed;
  }

  /**
   * @dev Holds number & validity of tokens locked for a given reason for
   *      a specified address
   */
  mapping(address => mapping(bytes32 => LockToken)) public locked;
}

pragma solidity ^0.5.0;

interface LegacyMCR {
  function addMCRData(uint mcrP, uint mcrE, uint vF, bytes4[] calldata curr, uint[] calldata _threeDayAvg, uint64 onlyDate) external;
  function addLastMCRData(uint64 date) external;
  function changeDependentContractAddress() external;
  function getAllSumAssurance() external view returns (uint amount);
  function _calVtpAndMCRtp(uint poolBalance) external view returns (uint vtp, uint mcrtp);
  function calculateStepTokenPrice(bytes4 curr, uint mcrtp) external view returns (uint tokenPrice);
  function calculateTokenPrice(bytes4 curr) external view returns (uint tokenPrice);
  function calVtpAndMCRtp() external view returns (uint vtp, uint mcrtp);
  function calculateVtpAndMCRtp(uint poolBalance) external view returns (uint vtp, uint mcrtp);
  function getThresholdValues(uint vtp, uint vF, uint totalSA, uint minCap) external view returns (uint lowerThreshold, uint upperThreshold);
  function getMaxSellTokens() external view returns (uint maxTokens);
  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val);
  function updateUintParameters(bytes8 code, uint val) external;

  function variableMincap() external view returns (uint);
  function dynamicMincapThresholdx100() external view returns (uint);
  function dynamicMincapIncrementx100() external view returns (uint);

  function getLastMCREther() external view returns (uint);
}

// /* Copyright (C) 2017 GovBlocks.io

//   This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.

//   This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.

//   You should have received a copy of the GNU General Public License
//     along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../token/TokenController.sol";
import "./MemberRoles.sol";
import "./ProposalCategory.sol";
import "./external/IGovernance.sol";

contract Governance is IGovernance, Iupgradable {

  using SafeMath for uint;

  enum ProposalStatus {
    Draft,
    AwaitingSolution,
    VotingStarted,
    Accepted,
    Rejected,
    Majority_Not_Reached_But_Accepted,
    Denied
  }

  struct ProposalData {
    uint propStatus;
    uint finalVerdict;
    uint category;
    uint commonIncentive;
    uint dateUpd;
    address owner;
  }

  struct ProposalVote {
    address voter;
    uint proposalId;
    uint dateAdd;
  }

  struct VoteTally {
    mapping(uint => uint) memberVoteValue;
    mapping(uint => uint) abVoteValue;
    uint voters;
  }

  struct DelegateVote {
    address follower;
    address leader;
    uint lastUpd;
  }

  ProposalVote[] internal allVotes;
  DelegateVote[] public allDelegation;

  mapping(uint => ProposalData) internal allProposalData;
  mapping(uint => bytes[]) internal allProposalSolutions;
  mapping(address => uint[]) internal allVotesByMember;
  mapping(uint => mapping(address => bool)) public rewardClaimed;
  mapping(address => mapping(uint => uint)) public memberProposalVote;
  mapping(address => uint) public followerDelegation;
  mapping(address => uint) internal followerCount;
  mapping(address => uint[]) internal leaderDelegation;
  mapping(uint => VoteTally) public proposalVoteTally;
  mapping(address => bool) public isOpenForDelegation;
  mapping(address => uint) public lastRewardClaimed;

  bool internal constructorCheck;
  uint public tokenHoldingTime;
  uint internal roleIdAllowedToCatgorize;
  uint internal maxVoteWeigthPer;
  uint internal specialResolutionMajPerc;
  uint internal maxFollowers;
  uint internal totalProposals;
  uint internal maxDraftTime;

  MemberRoles internal memberRole;
  ProposalCategory internal proposalCategory;
  TokenController internal tokenInstance;

  mapping(uint => uint) public proposalActionStatus;
  mapping(uint => uint) internal proposalExecutionTime;
  mapping(uint => mapping(address => bool)) public proposalRejectedByAB;
  mapping(uint => uint) internal actionRejectedCount;

  bool internal actionParamsInitialised;
  uint internal actionWaitingTime;
  uint constant internal AB_MAJ_TO_REJECT_ACTION = 3;

  enum ActionStatus {
    Pending,
    Accepted,
    Rejected,
    Executed,
    NoAction
  }

  /**
  * @dev Called whenever an action execution is failed.
  */
  event ActionFailed (
    uint256 proposalId
  );

  /**
  * @dev Called whenever an AB member rejects the action execution.
  */
  event ActionRejected (
    uint256 indexed proposalId,
    address rejectedBy
  );

  /**
  * @dev Checks if msg.sender is proposal owner
  */
  modifier onlyProposalOwner(uint _proposalId) {
    require(msg.sender == allProposalData[_proposalId].owner, "Not allowed");
    _;
  }

  /**
  * @dev Checks if proposal is opened for voting
  */
  modifier voteNotStarted(uint _proposalId) {
    require(allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted));
    _;
  }

  /**
  * @dev Checks if msg.sender is allowed to create proposal under given category
  */
  modifier isAllowed(uint _categoryId) {
    require(allowedToCreateProposal(_categoryId), "Not allowed");
    _;
  }

  /**
  * @dev Checks if msg.sender is allowed categorize proposal under given category
  */
  modifier isAllowedToCategorize() {
    require(memberRole.checkRole(msg.sender, roleIdAllowedToCatgorize), "Not allowed");
    _;
  }

  /**
  * @dev Checks if msg.sender had any pending rewards to be claimed
  */
  modifier checkPendingRewards {
    require(getPendingReward(msg.sender) == 0, "Claim reward");
    _;
  }

  /**
  * @dev Event emitted whenever a proposal is categorized
  */
  event ProposalCategorized(
    uint indexed proposalId,
    address indexed categorizedBy,
    uint categoryId
  );

  /**
   * @dev Removes delegation of an address.
   * @param _add address to undelegate.
   */
  function removeDelegation(address _add) external onlyInternal {
    _unDelegate(_add);
  }

  /**
  * @dev Creates a new proposal
  * @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
  * @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
  */
  function createProposal(
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash,
    uint _categoryId
  )
  external isAllowed(_categoryId)
  {
    require(ms.isMember(msg.sender), "Not Member");

    _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);
  }

  /**
  * @dev Edits the details of an existing proposal
  * @param _proposalId Proposal id that details needs to be updated
  * @param _proposalDescHash Proposal description hash having long and short description of proposal.
  */
  function updateProposal(
    uint _proposalId,
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash
  )
  external onlyProposalOwner(_proposalId)
  {
    require(
      allProposalSolutions[_proposalId].length < 2,
      "Not allowed"
    );
    allProposalData[_proposalId].propStatus = uint(ProposalStatus.Draft);
    allProposalData[_proposalId].category = 0;
    allProposalData[_proposalId].commonIncentive = 0;
    emit Proposal(
      allProposalData[_proposalId].owner,
      _proposalId,
      now,
      _proposalTitle,
      _proposalSD,
      _proposalDescHash
    );
  }

  /**
  * @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
  */
  function categorizeProposal(
    uint _proposalId,
    uint _categoryId,
    uint _incentive
  )
  external
  voteNotStarted(_proposalId) isAllowedToCategorize
  {
    _categorizeProposal(_proposalId, _categoryId, _incentive);
  }

  /**
  * @dev Submit proposal with solution
  * @param _proposalId Proposal id
  * @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
  */
  function submitProposalWithSolution(
    uint _proposalId,
    string calldata _solutionHash,
    bytes calldata _action
  )
  external
  onlyProposalOwner(_proposalId)
  {

    require(allProposalData[_proposalId].propStatus == uint(ProposalStatus.AwaitingSolution));

    _proposalSubmission(_proposalId, _solutionHash, _action);
  }

  /**
  * @dev Creates a new proposal with solution
  * @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
  * @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
  * @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
  */
  function createProposalwithSolution(
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash,
    uint _categoryId,
    string calldata _solutionHash,
    bytes calldata _action
  )
  external isAllowed(_categoryId)
  {


    uint proposalId = totalProposals;

    _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);

    require(_categoryId > 0);

    _proposalSubmission(
      proposalId,
      _solutionHash,
      _action
    );
  }

  /**
   * @dev Submit a vote on the proposal.
   * @param _proposalId to vote upon.
   * @param _solutionChosen is the chosen vote.
   */
  function submitVote(uint _proposalId, uint _solutionChosen) external {

    require(allProposalData[_proposalId].propStatus ==
      uint(Governance.ProposalStatus.VotingStarted), "Not allowed");

    require(_solutionChosen < allProposalSolutions[_proposalId].length);


    _submitVote(_proposalId, _solutionChosen);
  }

  /**
   * @dev Closes the proposal.
   * @param _proposalId of proposal to be closed.
   */
  function closeProposal(uint _proposalId) external {
    uint category = allProposalData[_proposalId].category;


    uint _memberRole;
    if (allProposalData[_proposalId].dateUpd.add(maxDraftTime) <= now &&
      allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted)) {
      _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
    } else {
      require(canCloseProposal(_proposalId) == 1);
      (, _memberRole,,,,,) = proposalCategory.category(allProposalData[_proposalId].category);
      if (_memberRole == uint(MemberRoles.Role.AdvisoryBoard)) {
        _closeAdvisoryBoardVote(_proposalId, category);
      } else {
        _closeMemberVote(_proposalId, category);
      }
    }

  }

  /**
   * @dev Claims reward for member.
   * @param _memberAddress to claim reward of.
   * @param _maxRecords maximum number of records to claim reward for.
   _proposals list of proposals of which reward will be claimed.
   * @return amount of pending reward.
   */
  function claimReward(address _memberAddress, uint _maxRecords)
  external returns (uint pendingDAppReward)
  {

    uint voteId;
    address leader;
    uint lastUpd;

    require(msg.sender == ms.getLatestAddress("CR"));

    uint delegationId = followerDelegation[_memberAddress];
    DelegateVote memory delegationData = allDelegation[delegationId];
    if (delegationId > 0 && delegationData.leader != address(0)) {
      leader = delegationData.leader;
      lastUpd = delegationData.lastUpd;
    } else
      leader = _memberAddress;

    uint proposalId;
    uint totalVotes = allVotesByMember[leader].length;
    uint lastClaimed = totalVotes;
    uint j;
    uint i;
    for (i = lastRewardClaimed[_memberAddress]; i < totalVotes && j < _maxRecords; i++) {
      voteId = allVotesByMember[leader][i];
      proposalId = allVotes[voteId].proposalId;
      if (proposalVoteTally[proposalId].voters > 0 && (allVotes[voteId].dateAdd > (
      lastUpd.add(tokenHoldingTime)) || leader == _memberAddress)) {
        if (allProposalData[proposalId].propStatus > uint(ProposalStatus.VotingStarted)) {
          if (!rewardClaimed[voteId][_memberAddress]) {
            pendingDAppReward = pendingDAppReward.add(
              allProposalData[proposalId].commonIncentive.div(
                proposalVoteTally[proposalId].voters
              )
            );
            rewardClaimed[voteId][_memberAddress] = true;
            j++;
          }
        } else {
          if (lastClaimed == totalVotes) {
            lastClaimed = i;
          }
        }
      }
    }

    if (lastClaimed == totalVotes) {
      lastRewardClaimed[_memberAddress] = i;
    } else {
      lastRewardClaimed[_memberAddress] = lastClaimed;
    }

    if (j > 0) {
      emit RewardClaimed(
        _memberAddress,
        pendingDAppReward
      );
    }
  }

  /**
   * @dev Sets delegation acceptance status of individual user
   * @param _status delegation acceptance status
   */
  function setDelegationStatus(bool _status) external isMemberAndcheckPause checkPendingRewards {
    isOpenForDelegation[msg.sender] = _status;
  }

  /**
   * @dev Delegates vote to an address.
   * @param _add is the address to delegate vote to.
   */
  function delegateVote(address _add) external isMemberAndcheckPause checkPendingRewards {

    require(ms.masterInitialized());

    require(allDelegation[followerDelegation[_add]].leader == address(0));

    if (followerDelegation[msg.sender] > 0) {
      require((allDelegation[followerDelegation[msg.sender]].lastUpd).add(tokenHoldingTime) < now);
    }

    require(!alreadyDelegated(msg.sender));
    require(!memberRole.checkRole(msg.sender, uint(MemberRoles.Role.Owner)));
    require(!memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)));


    require(followerCount[_add] < maxFollowers);

    if (allVotesByMember[msg.sender].length > 0) {
      require((allVotes[allVotesByMember[msg.sender][allVotesByMember[msg.sender].length - 1]].dateAdd).add(tokenHoldingTime)
        < now);
    }

    require(ms.isMember(_add));

    require(isOpenForDelegation[_add]);

    allDelegation.push(DelegateVote(msg.sender, _add, now));
    followerDelegation[msg.sender] = allDelegation.length - 1;
    leaderDelegation[_add].push(allDelegation.length - 1);
    followerCount[_add]++;
    lastRewardClaimed[msg.sender] = allVotesByMember[_add].length;
  }

  /**
   * @dev Undelegates the sender
   */
  function unDelegate() external isMemberAndcheckPause checkPendingRewards {
    _unDelegate(msg.sender);
  }

  /**
   * @dev Triggers action of accepted proposal after waiting time is finished
   */
  function triggerAction(uint _proposalId) external {
    require(proposalActionStatus[_proposalId] == uint(ActionStatus.Accepted) && proposalExecutionTime[_proposalId] <= now, "Cannot trigger");
    _triggerAction(_proposalId, allProposalData[_proposalId].category);
  }

  /**
   * @dev Provides option to Advisory board member to reject proposal action execution within actionWaitingTime, if found suspicious
   */
  function rejectAction(uint _proposalId) external {
    require(memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)) && proposalExecutionTime[_proposalId] > now);

    require(proposalActionStatus[_proposalId] == uint(ActionStatus.Accepted));

    require(!proposalRejectedByAB[_proposalId][msg.sender]);

    require(
      keccak256(proposalCategory.categoryActionHashes(allProposalData[_proposalId].category))
      != keccak256(abi.encodeWithSignature("swapABMember(address,address)"))
    );

    proposalRejectedByAB[_proposalId][msg.sender] = true;
    actionRejectedCount[_proposalId]++;
    emit ActionRejected(_proposalId, msg.sender);
    if (actionRejectedCount[_proposalId] == AB_MAJ_TO_REJECT_ACTION) {
      proposalActionStatus[_proposalId] = uint(ActionStatus.Rejected);
    }
  }

  /**
   * @dev Sets intial actionWaitingTime value
   * To be called after governance implementation has been updated
   */
  function setInitialActionParameters() external onlyOwner {
    require(!actionParamsInitialised);
    actionParamsInitialised = true;
    actionWaitingTime = 24 * 1 hours;
  }

  /**
   * @dev Gets Uint Parameters of a code
   * @param code whose details we want
   * @return string value of the code
   * @return associated amount (time or perc or value) to the code
   */
  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {

    codeVal = code;

    if (code == "GOVHOLD") {

      val = tokenHoldingTime / (1 days);

    } else if (code == "MAXFOL") {

      val = maxFollowers;

    } else if (code == "MAXDRFT") {

      val = maxDraftTime / (1 days);

    } else if (code == "EPTIME") {

      val = ms.pauseTime() / (1 days);

    } else if (code == "ACWT") {

      val = actionWaitingTime / (1 hours);

    }
  }

  /**
   * @dev Gets all details of a propsal
   * @param _proposalId whose details we want
   * @return proposalId
   * @return category
   * @return status
   * @return finalVerdict
   * @return totalReward
   */
  function proposal(uint _proposalId)
  external
  view
  returns (
    uint proposalId,
    uint category,
    uint status,
    uint finalVerdict,
    uint totalRewar
  )
  {
    return (
    _proposalId,
    allProposalData[_proposalId].category,
    allProposalData[_proposalId].propStatus,
    allProposalData[_proposalId].finalVerdict,
    allProposalData[_proposalId].commonIncentive
    );
  }

  /**
   * @dev Gets some details of a propsal
   * @param _proposalId whose details we want
   * @return proposalId
   * @return number of all proposal solutions
   * @return amount of votes
   */
  function proposalDetails(uint _proposalId) external view returns (uint, uint, uint) {
    return (
    _proposalId,
    allProposalSolutions[_proposalId].length,
    proposalVoteTally[_proposalId].voters
    );
  }

  /**
   * @dev Gets solution action on a proposal
   * @param _proposalId whose details we want
   * @param _solution whose details we want
   * @return action of a solution on a proposal
   */
  function getSolutionAction(uint _proposalId, uint _solution) external view returns (uint, bytes memory) {
    return (
    _solution,
    allProposalSolutions[_proposalId][_solution]
    );
  }

  /**
   * @dev Gets length of propsal
   * @return length of propsal
   */
  function getProposalLength() external view returns (uint) {
    return totalProposals;
  }

  /**
   * @dev Get followers of an address
   * @return get followers of an address
   */
  function getFollowers(address _add) external view returns (uint[] memory) {
    return leaderDelegation[_add];
  }

  /**
   * @dev Gets pending rewards of a member
   * @param _memberAddress in concern
   * @return amount of pending reward
   */
  function getPendingReward(address _memberAddress)
  public view returns (uint pendingDAppReward)
  {
    uint delegationId = followerDelegation[_memberAddress];
    address leader;
    uint lastUpd;
    DelegateVote memory delegationData = allDelegation[delegationId];

    if (delegationId > 0 && delegationData.leader != address(0)) {
      leader = delegationData.leader;
      lastUpd = delegationData.lastUpd;
    } else
      leader = _memberAddress;

    uint proposalId;
    for (uint i = lastRewardClaimed[_memberAddress]; i < allVotesByMember[leader].length; i++) {
      if (allVotes[allVotesByMember[leader][i]].dateAdd > (
      lastUpd.add(tokenHoldingTime)) || leader == _memberAddress) {
        if (!rewardClaimed[allVotesByMember[leader][i]][_memberAddress]) {
          proposalId = allVotes[allVotesByMember[leader][i]].proposalId;
          if (proposalVoteTally[proposalId].voters > 0 && allProposalData[proposalId].propStatus
          > uint(ProposalStatus.VotingStarted)) {
            pendingDAppReward = pendingDAppReward.add(
              allProposalData[proposalId].commonIncentive.div(
                proposalVoteTally[proposalId].voters
              )
            );
          }
        }
      }
    }
  }

  /**
   * @dev Updates Uint Parameters of a code
   * @param code whose details we want to update
   * @param val value to set
   */
  function updateUintParameters(bytes8 code, uint val) public {

    require(ms.checkIsAuthToGoverned(msg.sender));
    if (code == "GOVHOLD") {

      tokenHoldingTime = val * 1 days;

    } else if (code == "MAXFOL") {

      maxFollowers = val;

    } else if (code == "MAXDRFT") {

      maxDraftTime = val * 1 days;

    } else if (code == "EPTIME") {

      ms.updatePauseTime(val * 1 days);

    } else if (code == "ACWT") {

      actionWaitingTime = val * 1 hours;

    } else {

      revert("Invalid code");

    }
  }

  /**
  * @dev Updates all dependency addresses to latest ones from Master
  */
  function changeDependentContractAddress() public {
    tokenInstance = TokenController(ms.dAppLocker());
    memberRole = MemberRoles(ms.getLatestAddress("MR"));
    proposalCategory = ProposalCategory(ms.getLatestAddress("PC"));
  }

  /**
  * @dev Checks if msg.sender is allowed to create a proposal under given category
  */
  function allowedToCreateProposal(uint category) public view returns (bool check) {
    if (category == 0)
      return true;
    uint[] memory mrAllowed;
    (,,,, mrAllowed,,) = proposalCategory.category(category);
    for (uint i = 0; i < mrAllowed.length; i++) {
      if (mrAllowed[i] == 0 || memberRole.checkRole(msg.sender, mrAllowed[i]))
        return true;
    }
  }

  /**
   * @dev Checks if an address is already delegated
   * @param _add in concern
   * @return bool value if the address is delegated or not
   */
  function alreadyDelegated(address _add) public view returns (bool delegated) {
    for (uint i = 0; i < leaderDelegation[_add].length; i++) {
      if (allDelegation[leaderDelegation[_add][i]].leader == _add) {
        return true;
      }
    }
  }

  /**
  * @dev Checks If the proposal voting time is up and it's ready to close
  *      i.e. Closevalue is 1 if proposal is ready to be closed, 2 if already closed, 0 otherwise!
  * @param _proposalId Proposal id to which closing value is being checked
  */
  function canCloseProposal(uint _proposalId)
  public
  view
  returns (uint)
  {
    uint dateUpdate;
    uint pStatus;
    uint _closingTime;
    uint _roleId;
    uint majority;
    pStatus = allProposalData[_proposalId].propStatus;
    dateUpdate = allProposalData[_proposalId].dateUpd;
    (, _roleId, majority, , , _closingTime,) = proposalCategory.category(allProposalData[_proposalId].category);
    if (
      pStatus == uint(ProposalStatus.VotingStarted)
    ) {
      uint numberOfMembers = memberRole.numberOfMembers(_roleId);
      if (_roleId == uint(MemberRoles.Role.AdvisoryBoard)) {
        if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100).div(numberOfMembers) >= majority
        || proposalVoteTally[_proposalId].abVoteValue[1].add(proposalVoteTally[_proposalId].abVoteValue[0]) == numberOfMembers
          || dateUpdate.add(_closingTime) <= now) {

          return 1;
        }
      } else {
        if (numberOfMembers == proposalVoteTally[_proposalId].voters
          || dateUpdate.add(_closingTime) <= now)
          return 1;
      }
    } else if (pStatus > uint(ProposalStatus.VotingStarted)) {
      return 2;
    } else {
      return 0;
    }
  }

  /**
   * @dev Gets Id of member role allowed to categorize the proposal
   * @return roleId allowed to categorize the proposal
   */
  function allowedToCatgorize() public view returns (uint roleId) {
    return roleIdAllowedToCatgorize;
  }

  /**
   * @dev Gets vote tally data
   * @param _proposalId in concern
   * @param _solution of a proposal id
   * @return member vote value
   * @return advisory board vote value
   * @return amount of votes
   */
  function voteTallyData(uint _proposalId, uint _solution) public view returns (uint, uint, uint) {
    return (proposalVoteTally[_proposalId].memberVoteValue[_solution],
    proposalVoteTally[_proposalId].abVoteValue[_solution], proposalVoteTally[_proposalId].voters);
  }

  /**
   * @dev Internal call to create proposal
   * @param _proposalTitle of proposal
   * @param _proposalSD is short description of proposal
   * @param _proposalDescHash IPFS hash value of propsal
   * @param _categoryId of proposal
   */
  function _createProposal(
    string memory _proposalTitle,
    string memory _proposalSD,
    string memory _proposalDescHash,
    uint _categoryId
  )
  internal
  {
    require(proposalCategory.categoryABReq(_categoryId) == 0 || _categoryId == 0);
    uint _proposalId = totalProposals;
    allProposalData[_proposalId].owner = msg.sender;
    allProposalData[_proposalId].dateUpd = now;
    allProposalSolutions[_proposalId].push("");
    totalProposals++;

    emit Proposal(
      msg.sender,
      _proposalId,
      now,
      _proposalTitle,
      _proposalSD,
      _proposalDescHash
    );

    if (_categoryId > 0)
      _categorizeProposal(_proposalId, _categoryId, 0);
  }

  /**
   * @dev Internal call to categorize a proposal
   * @param _proposalId of proposal
   * @param _categoryId of proposal
   * @param _incentive is commonIncentive
   */
  function _categorizeProposal(
    uint _proposalId,
    uint _categoryId,
    uint _incentive
  )
  internal
  {
    require(
      _categoryId > 0 && _categoryId < proposalCategory.totalCategories(),
      "Invalid category"
    );
    allProposalData[_proposalId].category = _categoryId;
    allProposalData[_proposalId].commonIncentive = _incentive;
    allProposalData[_proposalId].propStatus = uint(ProposalStatus.AwaitingSolution);

    emit ProposalCategorized(_proposalId, msg.sender, _categoryId);
  }

  /**
   * @dev Internal call to add solution to a proposal
   * @param _proposalId in concern
   * @param _action on that solution
   * @param _solutionHash string value
   */
  function _addSolution(uint _proposalId, bytes memory _action, string memory _solutionHash)
  internal
  {
    allProposalSolutions[_proposalId].push(_action);
    emit Solution(_proposalId, msg.sender, allProposalSolutions[_proposalId].length - 1, _solutionHash, now);
  }

  /**
  * @dev Internal call to add solution and open proposal for voting
  */
  function _proposalSubmission(
    uint _proposalId,
    string memory _solutionHash,
    bytes memory _action
  )
  internal
  {

    uint _categoryId = allProposalData[_proposalId].category;
    if (proposalCategory.categoryActionHashes(_categoryId).length == 0) {
      require(keccak256(_action) == keccak256(""));
      proposalActionStatus[_proposalId] = uint(ActionStatus.NoAction);
    }

    _addSolution(
      _proposalId,
      _action,
      _solutionHash
    );

    _updateProposalStatus(_proposalId, uint(ProposalStatus.VotingStarted));
    (, , , , , uint closingTime,) = proposalCategory.category(_categoryId);
    emit CloseProposalOnTime(_proposalId, closingTime.add(now));

  }

  /**
   * @dev Internal call to submit vote
   * @param _proposalId of proposal in concern
   * @param _solution for that proposal
   */
  function _submitVote(uint _proposalId, uint _solution) internal {

    uint delegationId = followerDelegation[msg.sender];
    uint mrSequence;
    uint majority;
    uint closingTime;
    (, mrSequence, majority, , , closingTime,) = proposalCategory.category(allProposalData[_proposalId].category);

    require(allProposalData[_proposalId].dateUpd.add(closingTime) > now, "Closed");

    require(memberProposalVote[msg.sender][_proposalId] == 0, "Not allowed");
    require((delegationId == 0) || (delegationId > 0 && allDelegation[delegationId].leader == address(0) &&
    _checkLastUpd(allDelegation[delegationId].lastUpd)));

    require(memberRole.checkRole(msg.sender, mrSequence), "Not Authorized");
    uint totalVotes = allVotes.length;

    allVotesByMember[msg.sender].push(totalVotes);
    memberProposalVote[msg.sender][_proposalId] = totalVotes;

    allVotes.push(ProposalVote(msg.sender, _proposalId, now));

    emit Vote(msg.sender, _proposalId, totalVotes, now, _solution);
    if (mrSequence == uint(MemberRoles.Role.Owner)) {
      if (_solution == 1)
        _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), allProposalData[_proposalId].category, 1, MemberRoles.Role.Owner);
      else
        _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));

    } else {
      uint numberOfMembers = memberRole.numberOfMembers(mrSequence);
      _setVoteTally(_proposalId, _solution, mrSequence);

      if (mrSequence == uint(MemberRoles.Role.AdvisoryBoard)) {
        if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100).div(numberOfMembers)
        >= majority
          || (proposalVoteTally[_proposalId].abVoteValue[1].add(proposalVoteTally[_proposalId].abVoteValue[0])) == numberOfMembers) {
          emit VoteCast(_proposalId);
        }
      } else {
        if (numberOfMembers == proposalVoteTally[_proposalId].voters)
          emit VoteCast(_proposalId);
      }
    }

  }

  /**
   * @dev Internal call to set vote tally of a proposal
   * @param _proposalId of proposal in concern
   * @param _solution of proposal in concern
   * @param mrSequence number of members for a role
   */
  function _setVoteTally(uint _proposalId, uint _solution, uint mrSequence) internal
  {
    uint categoryABReq;
    uint isSpecialResolution;
    (, categoryABReq, isSpecialResolution) = proposalCategory.categoryExtendedData(allProposalData[_proposalId].category);
    if (memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)) && (categoryABReq > 0) ||
      mrSequence == uint(MemberRoles.Role.AdvisoryBoard)) {
      proposalVoteTally[_proposalId].abVoteValue[_solution]++;
    }
    tokenInstance.lockForMemberVote(msg.sender, tokenHoldingTime);
    if (mrSequence != uint(MemberRoles.Role.AdvisoryBoard)) {
      uint voteWeight;
      uint voters = 1;
      uint tokenBalance = tokenInstance.totalBalanceOf(msg.sender);
      uint totalSupply = tokenInstance.totalSupply();
      if (isSpecialResolution == 1) {
        voteWeight = tokenBalance.add(10 ** 18);
      } else {
        voteWeight = (_minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100))).add(10 ** 18);
      }
      DelegateVote memory delegationData;
      for (uint i = 0; i < leaderDelegation[msg.sender].length; i++) {
        delegationData = allDelegation[leaderDelegation[msg.sender][i]];
        if (delegationData.leader == msg.sender &&
          _checkLastUpd(delegationData.lastUpd)) {
          if (memberRole.checkRole(delegationData.follower, mrSequence)) {
            tokenBalance = tokenInstance.totalBalanceOf(delegationData.follower);
            tokenInstance.lockForMemberVote(delegationData.follower, tokenHoldingTime);
            voters++;
            if (isSpecialResolution == 1) {
              voteWeight = voteWeight.add(tokenBalance.add(10 ** 18));
            } else {
              voteWeight = voteWeight.add((_minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100))).add(10 ** 18));
            }
          }
        }
      }
      proposalVoteTally[_proposalId].memberVoteValue[_solution] = proposalVoteTally[_proposalId].memberVoteValue[_solution].add(voteWeight);
      proposalVoteTally[_proposalId].voters = proposalVoteTally[_proposalId].voters + voters;
    }
  }

  /**
   * @dev Gets minimum of two numbers
   * @param a one of the two numbers
   * @param b one of the two numbers
   * @return minimum number out of the two
   */
  function _minOf(uint a, uint b) internal pure returns (uint res) {
    res = a;
    if (res > b)
      res = b;
  }

  /**
   * @dev Check the time since last update has exceeded token holding time or not
   * @param _lastUpd is last update time
   * @return the bool which tells if the time since last update has exceeded token holding time or not
   */
  function _checkLastUpd(uint _lastUpd) internal view returns (bool) {
    return (now - _lastUpd) > tokenHoldingTime;
  }

  /**
  * @dev Checks if the vote count against any solution passes the threshold value or not.
  */
  function _checkForThreshold(uint _proposalId, uint _category) internal view returns (bool check) {
    uint categoryQuorumPerc;
    uint roleAuthorized;
    (, roleAuthorized, , categoryQuorumPerc, , ,) = proposalCategory.category(_category);
    check = ((proposalVoteTally[_proposalId].memberVoteValue[0]
    .add(proposalVoteTally[_proposalId].memberVoteValue[1]))
    .mul(100))
    .div(
      tokenInstance.totalSupply().add(
        memberRole.numberOfMembers(roleAuthorized).mul(10 ** 18)
      )
    ) >= categoryQuorumPerc;
  }

  /**
   * @dev Called when vote majority is reached
   * @param _proposalId of proposal in concern
   * @param _status of proposal in concern
   * @param category of proposal in concern
   * @param max vote value of proposal in concern
   */
  function _callIfMajReached(uint _proposalId, uint _status, uint category, uint max, MemberRoles.Role role) internal {

    allProposalData[_proposalId].finalVerdict = max;
    _updateProposalStatus(_proposalId, _status);
    emit ProposalAccepted(_proposalId);
    if (proposalActionStatus[_proposalId] != uint(ActionStatus.NoAction)) {
      if (role == MemberRoles.Role.AdvisoryBoard) {
        _triggerAction(_proposalId, category);
      } else {
        proposalActionStatus[_proposalId] = uint(ActionStatus.Accepted);
        proposalExecutionTime[_proposalId] = actionWaitingTime.add(now);
      }
    }
  }

  /**
   * @dev Internal function to trigger action of accepted proposal
   */
  function _triggerAction(uint _proposalId, uint _categoryId) internal {
    proposalActionStatus[_proposalId] = uint(ActionStatus.Executed);
    bytes2 contractName;
    address actionAddress;
    bytes memory _functionHash;
    (, actionAddress, contractName, , _functionHash) = proposalCategory.categoryActionDetails(_categoryId);
    if (contractName == "MS") {
      actionAddress = address(ms);
    } else if (contractName != "EX") {
      actionAddress = ms.getLatestAddress(contractName);
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool actionStatus,) = actionAddress.call(abi.encodePacked(_functionHash, allProposalSolutions[_proposalId][1]));
    if (actionStatus) {
      emit ActionSuccess(_proposalId);
    } else {
      proposalActionStatus[_proposalId] = uint(ActionStatus.Accepted);
      emit ActionFailed(_proposalId);
    }
  }

  /**
   * @dev Internal call to update proposal status
   * @param _proposalId of proposal in concern
   * @param _status of proposal to set
   */
  function _updateProposalStatus(uint _proposalId, uint _status) internal {
    if (_status == uint(ProposalStatus.Rejected) || _status == uint(ProposalStatus.Denied)) {
      proposalActionStatus[_proposalId] = uint(ActionStatus.NoAction);
    }
    allProposalData[_proposalId].dateUpd = now;
    allProposalData[_proposalId].propStatus = _status;
  }

  /**
   * @dev Internal call to undelegate a follower
   * @param _follower is address of follower to undelegate
   */
  function _unDelegate(address _follower) internal {
    uint followerId = followerDelegation[_follower];
    if (followerId > 0) {

      followerCount[allDelegation[followerId].leader] = followerCount[allDelegation[followerId].leader].sub(1);
      allDelegation[followerId].leader = address(0);
      allDelegation[followerId].lastUpd = now;

      lastRewardClaimed[_follower] = allVotesByMember[_follower].length;
    }
  }

  /**
   * @dev Internal call to close member voting
   * @param _proposalId of proposal in concern
   * @param category of proposal in concern
   */
  function _closeMemberVote(uint _proposalId, uint category) internal {
    uint isSpecialResolution;
    uint abMaj;
    (, abMaj, isSpecialResolution) = proposalCategory.categoryExtendedData(category);
    if (isSpecialResolution == 1) {
      uint acceptedVotePerc = proposalVoteTally[_proposalId].memberVoteValue[1].mul(100)
      .div(
        tokenInstance.totalSupply().add(
          memberRole.numberOfMembers(uint(MemberRoles.Role.Member)).mul(10 ** 18)
        ));
      if (acceptedVotePerc >= specialResolutionMajPerc) {
        _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
      } else {
        _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
      }
    } else {
      if (_checkForThreshold(_proposalId, category)) {
        uint majorityVote;
        (,, majorityVote,,,,) = proposalCategory.category(category);
        if (
          ((proposalVoteTally[_proposalId].memberVoteValue[1].mul(100))
          .div(proposalVoteTally[_proposalId].memberVoteValue[0]
          .add(proposalVoteTally[_proposalId].memberVoteValue[1])
          ))
          >= majorityVote
        ) {
          _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
        } else {
          _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));
        }
      } else {
        if (abMaj > 0 && proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
        .div(memberRole.numberOfMembers(uint(MemberRoles.Role.AdvisoryBoard))) >= abMaj) {
          _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
        } else {
          _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
        }
      }
    }

    if (proposalVoteTally[_proposalId].voters > 0) {
      tokenInstance.mint(ms.getLatestAddress("CR"), allProposalData[_proposalId].commonIncentive);
    }
  }

  /**
   * @dev Internal call to close advisory board voting
   * @param _proposalId of proposal in concern
   * @param category of proposal in concern
   */
  function _closeAdvisoryBoardVote(uint _proposalId, uint category) internal {
    uint _majorityVote;
    MemberRoles.Role _roleId = MemberRoles.Role.AdvisoryBoard;
    (,, _majorityVote,,,,) = proposalCategory.category(category);
    if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
    .div(memberRole.numberOfMembers(uint(_roleId))) >= _majorityVote) {
      _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, _roleId);
    } else {
      _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
    }

  }

}

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "../claims/ClaimsReward.sol";
import "../cover/QuotationData.sol";
import "../token/TokenController.sol";
import "../token/TokenData.sol";
import "../token/TokenFunctions.sol";
import "./Governance.sol";
import "./external/Governed.sol";

contract MemberRoles is Governed, Iupgradable {

  TokenController public tc;
  TokenData internal td;
  QuotationData internal qd;
  ClaimsReward internal cr;
  Governance internal gv;
  TokenFunctions internal tf;
  NXMToken public tk;

  struct MemberRoleDetails {
    uint memberCounter;
    mapping(address => bool) memberActive;
    address[] memberAddress;
    address authorized;
  }

  enum Role {UnAssigned, AdvisoryBoard, Member, Owner}

  event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);

  event switchedMembership(address indexed previousMember, address indexed newMember, uint timeStamp);

  event ClaimPayoutAddressSet(address indexed member, address indexed payoutAddress);

  MemberRoleDetails[] internal memberRoleData;
  bool internal constructorCheck;
  uint public maxABCount;
  bool public launched;
  uint public launchedOn;

  mapping (address => address payable) internal claimPayoutAddress;

  modifier checkRoleAuthority(uint _memberRoleId) {
    if (memberRoleData[_memberRoleId].authorized != address(0))
      require(msg.sender == memberRoleData[_memberRoleId].authorized);
    else
      require(isAuthorizedToGovern(msg.sender), "Not Authorized");
    _;
  }

  /**
   * @dev to swap advisory board member
   * @param _newABAddress is address of new AB member
   * @param _removeAB is advisory board member to be removed
   */
  function swapABMember(
    address _newABAddress,
    address _removeAB
  )
  external
  checkRoleAuthority(uint(Role.AdvisoryBoard)) {

    _updateRole(_newABAddress, uint(Role.AdvisoryBoard), true);
    _updateRole(_removeAB, uint(Role.AdvisoryBoard), false);

  }

  /**
   * @dev to swap the owner address
   * @param _newOwnerAddress is the new owner address
   */
  function swapOwner(
    address _newOwnerAddress
  )
  external {
    require(msg.sender == address(ms));
    _updateRole(ms.owner(), uint(Role.Owner), false);
    _updateRole(_newOwnerAddress, uint(Role.Owner), true);
  }

  /**
   * @dev is used to add initital advisory board members
   * @param abArray is the list of initial advisory board members
   */
  function addInitialABMembers(address[] calldata abArray) external onlyOwner {

    //Ensure that NXMaster has initialized.
    require(ms.masterInitialized());

    require(maxABCount >=
      SafeMath.add(numberOfMembers(uint(Role.AdvisoryBoard)), abArray.length)
    );
    //AB count can't exceed maxABCount
    for (uint i = 0; i < abArray.length; i++) {
      require(checkRole(abArray[i], uint(MemberRoles.Role.Member)));
      _updateRole(abArray[i], uint(Role.AdvisoryBoard), true);
    }
  }

  /**
   * @dev to change max number of AB members allowed
   * @param _val is the new value to be set
   */
  function changeMaxABCount(uint _val) external onlyInternal {
    maxABCount = _val;
  }

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public {
    td = TokenData(ms.getLatestAddress("TD"));
    cr = ClaimsReward(ms.getLatestAddress("CR"));
    qd = QuotationData(ms.getLatestAddress("QD"));
    gv = Governance(ms.getLatestAddress("GV"));
    tf = TokenFunctions(ms.getLatestAddress("TF"));
    tk = NXMToken(ms.tokenAddress());
    tc = TokenController(ms.getLatestAddress("TC"));
  }

  /**
   * @dev to change the master address
   * @param _masterAddress is the new master address
   */
  function changeMasterAddress(address _masterAddress) public {

    if (masterAddress != address(0)) {
      require(masterAddress == msg.sender);
    }

    masterAddress = _masterAddress;
    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;
  }

  /**
   * @dev to initiate the member roles
   * @param _firstAB is the address of the first AB member
   * @param memberAuthority is the authority (role) of the member
   */
  function memberRolesInitiate(address _firstAB, address memberAuthority) public {
    require(!constructorCheck);
    _addInitialMemberRoles(_firstAB, memberAuthority);
    constructorCheck = true;
  }

  /// @dev Adds new member role
  /// @param _roleName New role name
  /// @param _roleDescription New description hash
  /// @param _authorized Authorized member against every role id
  function addRole(//solhint-disable-line
    bytes32 _roleName,
    string memory _roleDescription,
    address _authorized
  )
  public
  onlyAuthorizedToGovern {
    _addRole(_roleName, _roleDescription, _authorized);
  }

  /// @dev Assign or Delete a member from specific role.
  /// @param _memberAddress Address of Member
  /// @param _roleId RoleId to update
  /// @param _active active is set to be True if we want to assign this role to member, False otherwise!
  function updateRole(//solhint-disable-line
    address _memberAddress,
    uint _roleId,
    bool _active
  )
  public
  checkRoleAuthority(_roleId) {
    _updateRole(_memberAddress, _roleId, _active);
  }

  /**
   * @dev to add members before launch
   * @param userArray is list of addresses of members
   * @param tokens is list of tokens minted for each array element
   */
  function addMembersBeforeLaunch(address[] memory userArray, uint[] memory tokens) public onlyOwner {
    require(!launched);

    for (uint i = 0; i < userArray.length; i++) {
      require(!ms.isMember(userArray[i]));
      tc.addToWhitelist(userArray[i]);
      _updateRole(userArray[i], uint(Role.Member), true);
      tc.mint(userArray[i], tokens[i]);
    }
    launched = true;
    launchedOn = now;

  }

  /**
    * @dev Called by user to pay joining membership fee
    */
  function payJoiningFee(address _userAddress) public payable {
    require(_userAddress != address(0));
    require(!ms.isPause(), "Emergency Pause Applied");
    if (msg.sender == address(ms.getLatestAddress("QT"))) {
      require(td.walletAddress() != address(0), "No walletAddress present");
      tc.addToWhitelist(_userAddress);
      _updateRole(_userAddress, uint(Role.Member), true);
      td.walletAddress().transfer(msg.value);
    } else {
      require(!qd.refundEligible(_userAddress));
      require(!ms.isMember(_userAddress));
      require(msg.value == td.joiningFee());
      qd.setRefundEligible(_userAddress, true);
    }
  }

  /**
   * @dev to perform kyc verdict
   * @param _userAddress whose kyc is being performed
   * @param verdict of kyc process
   */
  function kycVerdict(address payable _userAddress, bool verdict) public {

    require(msg.sender == qd.kycAuthAddress());
    require(!ms.isPause());
    require(_userAddress != address(0));
    require(!ms.isMember(_userAddress));
    require(qd.refundEligible(_userAddress));
    if (verdict) {
      qd.setRefundEligible(_userAddress, false);
      uint fee = td.joiningFee();
      tc.addToWhitelist(_userAddress);
      _updateRole(_userAddress, uint(Role.Member), true);
      td.walletAddress().transfer(fee); // solhint-disable-line

    } else {
      qd.setRefundEligible(_userAddress, false);
      _userAddress.transfer(td.joiningFee()); // solhint-disable-line
    }
  }

  /**
   * @dev withdraws membership for msg.sender if currently a member.
   */
  function withdrawMembership() public {

    require(!ms.isPause() && ms.isMember(msg.sender));
    require(tc.totalLockedBalance(msg.sender) == 0); // solhint-disable-line
    require(!tf.isLockedForMemberVote(msg.sender)); // No locked tokens for Member/Governance voting
    require(cr.getAllPendingRewardOfUser(msg.sender) == 0); // No pending reward to be claimed(claim assesment).

    gv.removeDelegation(msg.sender);
    tc.burnFrom(msg.sender, tk.balanceOf(msg.sender));
    _updateRole(msg.sender, uint(Role.Member), false);
    tc.removeFromWhitelist(msg.sender); // need clarification on whitelist

    if (claimPayoutAddress[msg.sender] != address(0)) {
      claimPayoutAddress[msg.sender] = address(0);
      emit ClaimPayoutAddressSet(msg.sender, address(0));
    }
  }

  /**
   * @dev switches membership for msg.sender to the specified address.
   * @param newAddress address of user to forward membership.
   */
  function switchMembership(address newAddress) external {
    _switchMembership(msg.sender, newAddress);
    tk.transferFrom(msg.sender, newAddress, tk.balanceOf(msg.sender));
  }

  function switchMembershipOf(address member, address newAddress) external onlyInternal {
    _switchMembership(member, newAddress);
  }

  /**
   * @dev switches membership for member to the specified address.
   * @param newAddress address of user to forward membership.
   */
  function _switchMembership(address member, address newAddress) internal {

    require(!ms.isPause() && ms.isMember(member) && !ms.isMember(newAddress));
    require(tc.totalLockedBalance(member) == 0); // solhint-disable-line
    require(!tf.isLockedForMemberVote(member)); // No locked tokens for Member/Governance voting
    require(cr.getAllPendingRewardOfUser(member) == 0); // No pending reward to be claimed(claim assesment).

    gv.removeDelegation(member);
    tc.addToWhitelist(newAddress);
    _updateRole(newAddress, uint(Role.Member), true);
    _updateRole(member, uint(Role.Member), false);
    tc.removeFromWhitelist(member);

    address payable previousPayoutAddress = claimPayoutAddress[member];

    if (previousPayoutAddress != address(0)) {

      address payable storedAddress = previousPayoutAddress == newAddress ? address(0) : previousPayoutAddress;

      claimPayoutAddress[member] = address(0);
      claimPayoutAddress[newAddress] = storedAddress;

      // emit event for old address reset
      emit ClaimPayoutAddressSet(member, address(0));

      if (storedAddress != address(0)) {
        // emit event for setting the payout address on the new member address if it's non zero
        emit ClaimPayoutAddressSet(newAddress, storedAddress);
      }
    }

    emit switchedMembership(member, newAddress, now);
  }

  function getClaimPayoutAddress(address payable _member) external view returns (address payable) {
    address payable payoutAddress = claimPayoutAddress[_member];
    return payoutAddress != address(0) ? payoutAddress : _member;
  }

  function setClaimPayoutAddress(address payable _address) external {

    require(!ms.isPause(), "system is paused");
    require(ms.isMember(msg.sender), "sender is not a member");
    require(_address != msg.sender, "should be different than the member address");

    claimPayoutAddress[msg.sender] = _address;
    emit ClaimPayoutAddressSet(msg.sender, _address);
  }

  /// @dev Return number of member roles
  function totalRoles() public view returns (uint256) {//solhint-disable-line
    return memberRoleData.length;
  }

  /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
  /// @param _roleId roleId to update its Authorized Address
  /// @param _newAuthorized New authorized address against role id
  function changeAuthorized(uint _roleId, address _newAuthorized) public checkRoleAuthority(_roleId) {//solhint-disable-line
    memberRoleData[_roleId].authorized = _newAuthorized;
  }

  /// @dev Gets the member addresses assigned by a specific role
  /// @param _memberRoleId Member role id
  /// @return roleId Role id
  /// @return allMemberAddress Member addresses of specified role id
  function members(uint _memberRoleId) public view returns (uint, address[] memory memberArray) {//solhint-disable-line
    uint length = memberRoleData[_memberRoleId].memberAddress.length;
    uint i;
    uint j = 0;
    memberArray = new address[](memberRoleData[_memberRoleId].memberCounter);
    for (i = 0; i < length; i++) {
      address member = memberRoleData[_memberRoleId].memberAddress[i];
      if (memberRoleData[_memberRoleId].memberActive[member] && !_checkMemberInArray(member, memberArray)) {//solhint-disable-line
        memberArray[j] = member;
        j++;
      }
    }

    return (_memberRoleId, memberArray);
  }

  /// @dev Gets all members' length
  /// @param _memberRoleId Member role id
  /// @return memberRoleData[_memberRoleId].memberCounter Member length
  function numberOfMembers(uint _memberRoleId) public view returns (uint) {//solhint-disable-line
    return memberRoleData[_memberRoleId].memberCounter;
  }

  /// @dev Return member address who holds the right to add/remove any member from specific role.
  function authorized(uint _memberRoleId) public view returns (address) {//solhint-disable-line
    return memberRoleData[_memberRoleId].authorized;
  }

  /// @dev Get All role ids array that has been assigned to a member so far.
  function roles(address _memberAddress) public view returns (uint[] memory) {//solhint-disable-line
    uint length = memberRoleData.length;
    uint[] memory assignedRoles = new uint[](length);
    uint counter = 0;
    for (uint i = 1; i < length; i++) {
      if (memberRoleData[i].memberActive[_memberAddress]) {
        assignedRoles[counter] = i;
        counter++;
      }
    }
    return assignedRoles;
  }

  /// @dev Returns true if the given role id is assigned to a member.
  /// @param _memberAddress Address of member
  /// @param _roleId Checks member's authenticity with the roleId.
  /// i.e. Returns true if this roleId is assigned to member
  function checkRole(address _memberAddress, uint _roleId) public view returns (bool) {//solhint-disable-line
    if (_roleId == uint(Role.UnAssigned))
      return true;
    else
      if (memberRoleData[_roleId].memberActive[_memberAddress]) //solhint-disable-line
        return true;
      else
        return false;
  }

  /// @dev Return total number of members assigned against each role id.
  /// @return totalMembers Total members in particular role id
  function getMemberLengthForAllRoles() public view returns (uint[] memory totalMembers) {//solhint-disable-line
    totalMembers = new uint[](memberRoleData.length);
    for (uint i = 0; i < memberRoleData.length; i++) {
      totalMembers[i] = numberOfMembers(i);
    }
  }

  /**
   * @dev to update the member roles
   * @param _memberAddress in concern
   * @param _roleId the id of role
   * @param _active if active is true, add the member, else remove it
   */
  function _updateRole(address _memberAddress,
    uint _roleId,
    bool _active) internal {
    // require(_roleId != uint(Role.TokenHolder), "Membership to Token holder is detected automatically");
    if (_active) {
      require(!memberRoleData[_roleId].memberActive[_memberAddress]);
      memberRoleData[_roleId].memberCounter = SafeMath.add(memberRoleData[_roleId].memberCounter, 1);
      memberRoleData[_roleId].memberActive[_memberAddress] = true;
      memberRoleData[_roleId].memberAddress.push(_memberAddress);
    } else {
      require(memberRoleData[_roleId].memberActive[_memberAddress]);
      memberRoleData[_roleId].memberCounter = SafeMath.sub(memberRoleData[_roleId].memberCounter, 1);
      delete memberRoleData[_roleId].memberActive[_memberAddress];
    }
  }

  /// @dev Adds new member role
  /// @param _roleName New role name
  /// @param _roleDescription New description hash
  /// @param _authorized Authorized member against every role id
  function _addRole(
    bytes32 _roleName,
    string memory _roleDescription,
    address _authorized
  ) internal {
    emit MemberRole(memberRoleData.length, _roleName, _roleDescription);
    memberRoleData.push(MemberRoleDetails(0, new address[](0), _authorized));
  }

  /**
   * @dev to check if member is in the given member array
   * @param _memberAddress in concern
   * @param memberArray in concern
   * @return boolean to represent the presence
   */
  function _checkMemberInArray(
    address _memberAddress,
    address[] memory memberArray
  )
  internal
  pure
  returns (bool memberExists)
  {
    uint i;
    for (i = 0; i < memberArray.length; i++) {
      if (memberArray[i] == _memberAddress) {
        memberExists = true;
        break;
      }
    }
  }

  /**
   * @dev to add initial member roles
   * @param _firstAB is the member address to be added
   * @param memberAuthority is the member authority(role) to be added for
   */
  function _addInitialMemberRoles(address _firstAB, address memberAuthority) internal {
    maxABCount = 5;
    _addRole("Unassigned", "Unassigned", address(0));
    _addRole(
      "Advisory Board",
      "Selected few members that are deeply entrusted by the dApp. An ideal advisory board should be a mix of skills of domain, governance, research, technology, consulting etc to improve the performance of the dApp.", //solhint-disable-line
      address(0)
    );
    _addRole(
      "Member",
      "Represents all users of Mutual.", //solhint-disable-line
      memberAuthority
    );
    _addRole(
      "Owner",
      "Represents Owner of Mutual.", //solhint-disable-line
      address(0)
    );
    // _updateRole(_firstAB, uint(Role.AdvisoryBoard), true);
    _updateRole(_firstAB, uint(Role.Owner), true);
    // _updateRole(_firstAB, uint(Role.Member), true);
    launchedOn = 0;
  }

  function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool) {
    address memberAddress = memberRoleData[_memberRoleId].memberAddress[index];
    return (memberAddress, memberRoleData[_memberRoleId].memberActive[memberAddress]);
  }

  function membersLength(uint _memberRoleId) external view returns (uint) {
    return memberRoleData[_memberRoleId].memberAddress.length;
  }
}

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */
pragma solidity ^0.5.0;

import "../../abstract/Iupgradable.sol";
import "./MemberRoles.sol";
import "./external/Governed.sol";
import "./external/IProposalCategory.sol";

contract ProposalCategory is Governed, IProposalCategory, Iupgradable {

  bool public constructorCheck;
  MemberRoles internal mr;

  struct CategoryStruct {
    uint memberRoleToVote;
    uint majorityVotePerc;
    uint quorumPerc;
    uint[] allowedToCreateProposal;
    uint closingTime;
    uint minStake;
  }

  struct CategoryAction {
    uint defaultIncentive;
    address contractAddress;
    bytes2 contractName;
  }

  CategoryStruct[] internal allCategory;
  mapping(uint => CategoryAction) internal categoryActionData;
  mapping(uint => uint) public categoryABReq;
  mapping(uint => uint) public isSpecialResolution;
  mapping(uint => bytes) public categoryActionHashes;

  bool public categoryActionHashUpdated;

  /**
  * @dev Adds new category (Discontinued, moved functionality to newCategory)
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  */
  function addCategory(
    string calldata _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] calldata _allowedToCreateProposal,
    uint _closingTime,
    string calldata _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] calldata _incentives
  ) external {}

  /**
  * @dev Initiates Default settings for Proposal Category contract (Adding default categories)
  */
  function proposalCategoryInitiate() external {}

  /**
  * @dev Initiates Default action function hashes for existing categories
  * To be called after the contract has been upgraded by governance
  */
  function updateCategoryActionHashes() external onlyOwner {

    require(!categoryActionHashUpdated, "Category action hashes already updated");
    categoryActionHashUpdated = true;
    categoryActionHashes[1] = abi.encodeWithSignature("addRole(bytes32,string,address)");
    categoryActionHashes[2] = abi.encodeWithSignature("updateRole(address,uint256,bool)");
    categoryActionHashes[3] = abi.encodeWithSignature("newCategory(string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)"); // solhint-disable-line
    categoryActionHashes[4] = abi.encodeWithSignature("editCategory(uint256,string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)"); // solhint-disable-line
    categoryActionHashes[5] = abi.encodeWithSignature("upgradeContractImplementation(bytes2,address)");
    categoryActionHashes[6] = abi.encodeWithSignature("startEmergencyPause()");
    categoryActionHashes[7] = abi.encodeWithSignature("addEmergencyPause(bool,bytes4)");
    categoryActionHashes[8] = abi.encodeWithSignature("burnCAToken(uint256,uint256,address)");
    categoryActionHashes[9] = abi.encodeWithSignature("setUserClaimVotePausedOn(address)");
    categoryActionHashes[12] = abi.encodeWithSignature("transferEther(uint256,address)");
    categoryActionHashes[13] = abi.encodeWithSignature("addInvestmentAssetCurrency(bytes4,address,bool,uint64,uint64,uint8)"); // solhint-disable-line
    categoryActionHashes[14] = abi.encodeWithSignature("changeInvestmentAssetHoldingPerc(bytes4,uint64,uint64)");
    categoryActionHashes[15] = abi.encodeWithSignature("changeInvestmentAssetStatus(bytes4,bool)");
    categoryActionHashes[16] = abi.encodeWithSignature("swapABMember(address,address)");
    categoryActionHashes[17] = abi.encodeWithSignature("addCurrencyAssetCurrency(bytes4,address,uint256)");
    categoryActionHashes[20] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[21] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[22] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[23] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[24] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[25] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[26] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[27] = abi.encodeWithSignature("updateAddressParameters(bytes8,address)");
    categoryActionHashes[28] = abi.encodeWithSignature("updateOwnerParameters(bytes8,address)");
    categoryActionHashes[29] = abi.encodeWithSignature("upgradeMultipleContracts(bytes2[],address[])");
    categoryActionHashes[30] = abi.encodeWithSignature("changeCurrencyAssetAddress(bytes4,address)");
    categoryActionHashes[31] = abi.encodeWithSignature("changeCurrencyAssetBaseMin(bytes4,uint256)");
    categoryActionHashes[32] = abi.encodeWithSignature("changeInvestmentAssetAddressAndDecimal(bytes4,address,uint8)"); // solhint-disable-line
    categoryActionHashes[33] = abi.encodeWithSignature("externalLiquidityTrade()");
  }

  /**
  * @dev Gets Total number of categories added till now
  */
  function totalCategories() external view returns (uint) {
    return allCategory.length;
  }

  /**
  * @dev Gets category details
  */
  function category(uint _categoryId) external view returns (uint, uint, uint, uint, uint[] memory, uint, uint) {
    return (
    _categoryId,
    allCategory[_categoryId].memberRoleToVote,
    allCategory[_categoryId].majorityVotePerc,
    allCategory[_categoryId].quorumPerc,
    allCategory[_categoryId].allowedToCreateProposal,
    allCategory[_categoryId].closingTime,
    allCategory[_categoryId].minStake
    );
  }

  /**
  * @dev Gets category ab required and isSpecialResolution
  * @return the category id
  * @return if AB voting is required
  * @return is category a special resolution
  */
  function categoryExtendedData(uint _categoryId) external view returns (uint, uint, uint) {
    return (
    _categoryId,
    categoryABReq[_categoryId],
    isSpecialResolution[_categoryId]
    );
  }

  /**
   * @dev Gets the category acion details
   * @param _categoryId is the category id in concern
   * @return the category id
   * @return the contract address
   * @return the contract name
   * @return the default incentive
   */
  function categoryAction(uint _categoryId) external view returns (uint, address, bytes2, uint) {

    return (
    _categoryId,
    categoryActionData[_categoryId].contractAddress,
    categoryActionData[_categoryId].contractName,
    categoryActionData[_categoryId].defaultIncentive
    );
  }

  /**
   * @dev Gets the category acion details of a category id
   * @param _categoryId is the category id in concern
   * @return the category id
   * @return the contract address
   * @return the contract name
   * @return the default incentive
   * @return action function hash
   */
  function categoryActionDetails(uint _categoryId) external view returns (uint, address, bytes2, uint, bytes memory) {
    return (
    _categoryId,
    categoryActionData[_categoryId].contractAddress,
    categoryActionData[_categoryId].contractName,
    categoryActionData[_categoryId].defaultIncentive,
    categoryActionHashes[_categoryId]
    );
  }

  /**
  * @dev Updates dependant contract addresses
  */
  function changeDependentContractAddress() public {
    mr = MemberRoles(ms.getLatestAddress("MR"));
  }

  /**
  * @dev Adds new category
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  * @param _functionHash function signature to be executed
  */
  function newCategory(
    string memory _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] memory _allowedToCreateProposal,
    uint _closingTime,
    string memory _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] memory _incentives,
    string memory _functionHash
  )
  public
  onlyAuthorizedToGovern
  {

    require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

    require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

    require(_incentives[3] <= 1, "Invalid special resolution flag");

    //If category is special resolution role authorized should be member
    if (_incentives[3] == 1) {
      require(_memberRoleToVote == uint(MemberRoles.Role.Member));
      _majorityVotePerc = 0;
      _quorumPerc = 0;
    }

    _addCategory(
      _name,
      _memberRoleToVote,
      _majorityVotePerc,
      _quorumPerc,
      _allowedToCreateProposal,
      _closingTime,
      _actionHash,
      _contractAddress,
      _contractName,
      _incentives
    );


    if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
      categoryActionHashes[allCategory.length - 1] = abi.encodeWithSignature(_functionHash);
    }
  }

  /**
   * @dev Changes the master address and update it's instance
   * @param _masterAddress is the new master address
   */
  function changeMasterAddress(address _masterAddress) public {
    if (masterAddress != address(0))
      require(masterAddress == msg.sender);
    masterAddress = _masterAddress;
    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;

  }

  /**
  * @dev Updates category details (Discontinued, moved functionality to editCategory)
  * @param _categoryId Category id that needs to be updated
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  */
  function updateCategory(
    uint _categoryId,
    string memory _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] memory _allowedToCreateProposal,
    uint _closingTime,
    string memory _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] memory _incentives
  ) public {}

  /**
  * @dev Updates category details
  * @param _categoryId Category id that needs to be updated
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  * @param _functionHash function signature to be executed
  */
  function editCategory(
    uint _categoryId,
    string memory _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] memory _allowedToCreateProposal,
    uint _closingTime,
    string memory _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] memory _incentives,
    string memory _functionHash
  )
  public
  onlyAuthorizedToGovern
  {
    require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");

    require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

    require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

    require(_incentives[3] <= 1, "Invalid special resolution flag");

    //If category is special resolution role authorized should be member
    if (_incentives[3] == 1) {
      require(_memberRoleToVote == uint(MemberRoles.Role.Member));
      _majorityVotePerc = 0;
      _quorumPerc = 0;
    }

    delete categoryActionHashes[_categoryId];
    if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
      categoryActionHashes[_categoryId] = abi.encodeWithSignature(_functionHash);
    }
    allCategory[_categoryId].memberRoleToVote = _memberRoleToVote;
    allCategory[_categoryId].majorityVotePerc = _majorityVotePerc;
    allCategory[_categoryId].closingTime = _closingTime;
    allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal;
    allCategory[_categoryId].minStake = _incentives[0];
    allCategory[_categoryId].quorumPerc = _quorumPerc;
    categoryActionData[_categoryId].defaultIncentive = _incentives[1];
    categoryActionData[_categoryId].contractName = _contractName;
    categoryActionData[_categoryId].contractAddress = _contractAddress;
    categoryABReq[_categoryId] = _incentives[2];
    isSpecialResolution[_categoryId] = _incentives[3];
    emit Category(_categoryId, _name, _actionHash);
  }

  /**
  * @dev Internal call to add new category
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  */
  function _addCategory(
    string memory _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] memory _allowedToCreateProposal,
    uint _closingTime,
    string memory _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] memory _incentives
  )
  internal
  {
    require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");
    allCategory.push(
      CategoryStruct(
        _memberRoleToVote,
        _majorityVotePerc,
        _quorumPerc,
        _allowedToCreateProposal,
        _closingTime,
        _incentives[0]
      )
    );
    uint categoryId = allCategory.length - 1;
    categoryActionData[categoryId] = CategoryAction(_incentives[1], _contractAddress, _contractName);
    categoryABReq[categoryId] = _incentives[2];
    isSpecialResolution[categoryId] = _incentives[3];
    emit Category(categoryId, _name, _actionHash);
  }

  /**
  * @dev Internal call to check if given roles are valid or not
  */
  function _verifyMemberRoles(uint _memberRoleToVote, uint[] memory _allowedToCreateProposal)
  internal view returns (uint) {
    uint totalRoles = mr.totalRoles();
    if (_memberRoleToVote >= totalRoles) {
      return 0;
    }
    for (uint i = 0; i < _allowedToCreateProposal.length; i++) {
      if (_allowedToCreateProposal[i] >= totalRoles) {
        return 0;
      }
    }
    return 1;
  }

}

/* Copyright (C) 2017 GovBlocks.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

contract IGovernance {

  event Proposal(
    address indexed proposalOwner,
    uint256 indexed proposalId,
    uint256 dateAdd,
    string proposalTitle,
    string proposalSD,
    string proposalDescHash
  );

  event Solution(
    uint256 indexed proposalId,
    address indexed solutionOwner,
    uint256 indexed solutionId,
    string solutionDescHash,
    uint256 dateAdd
  );

  event Vote(
    address indexed from,
    uint256 indexed proposalId,
    uint256 indexed voteId,
    uint256 dateAdd,
    uint256 solutionChosen
  );

  event RewardClaimed(
    address indexed member,
    uint gbtReward
  );

  /// @dev VoteCast event is called whenever a vote is cast that can potentially close the proposal.
  event VoteCast (uint256 proposalId);

  /// @dev ProposalAccepted event is called when a proposal is accepted so that a server can listen that can
  ///      call any offchain actions
  event ProposalAccepted (uint256 proposalId);

  /// @dev CloseProposalOnTime event is called whenever a proposal is created or updated to close it on time.
  event CloseProposalOnTime (
    uint256 indexed proposalId,
    uint256 time
  );

  /// @dev ActionSuccess event is called whenever an onchain action is executed.
  event ActionSuccess (
    uint256 proposalId
  );

  /// @dev Creates a new proposal
  /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
  /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
  function createProposal(
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash,
    uint _categoryId
  )
  external;

  /// @dev Edits the details of an existing proposal and creates new version
  /// @param _proposalId Proposal id that details needs to be updated
  /// @param _proposalDescHash Proposal description hash having long and short description of proposal.
  function updateProposal(
    uint _proposalId,
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash
  )
  external;

  /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
  function categorizeProposal(
    uint _proposalId,
    uint _categoryId,
    uint _incentives
  )
  external;

  /// @dev Submit proposal with solution
  /// @param _proposalId Proposal id
  /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
  function submitProposalWithSolution(
    uint _proposalId,
    string calldata _solutionHash,
    bytes calldata _action
  )
  external;

  /// @dev Creates a new proposal with solution and votes for the solution
  /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
  /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
  /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
  function createProposalwithSolution(
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash,
    uint _categoryId,
    string calldata _solutionHash,
    bytes calldata _action
  )
  external;

  /// @dev Casts vote
  /// @param _proposalId Proposal id
  /// @param _solutionChosen solution chosen while voting. _solutionChosen[0] is the chosen solution
  function submitVote(uint _proposalId, uint _solutionChosen) external;

  function closeProposal(uint _proposalId) external;

  function claimReward(address _memberAddress, uint _maxRecords) external returns (uint pendingDAppReward);

  function proposal(uint _proposalId)
  external
  view
  returns (
    uint proposalId,
    uint category,
    uint status,
    uint finalVerdict,
    uint totalReward
  );

  function canCloseProposal(uint _proposalId) public view returns (uint closeValue);

  function allowedToCatgorize() public view returns (uint roleId);

}

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;


interface IMaster {
  function getLatestAddress(bytes2 _module) external view returns (address);
}

contract Governed {

  address public masterAddress; // Name of the dApp, needs to be set by contracts inheriting this contract

  /// @dev modifier that allows only the authorized addresses to execute the function
  modifier onlyAuthorizedToGovern() {
    IMaster ms = IMaster(masterAddress);
    require(ms.getLatestAddress("GV") == msg.sender, "Not authorized");
    _;
  }

  /// @dev checks if an address is authorized to govern
  function isAuthorizedToGovern(address _toCheck) public view returns (bool) {
    IMaster ms = IMaster(masterAddress);
    return (ms.getLatestAddress("GV") == _toCheck);
  }

}

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

contract IProposalCategory {

  event Category(
    uint indexed categoryId,
    string categoryName,
    string actionHash
  );

  /// @dev Adds new category
  /// @param _name Category name
  /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  /// @param _allowedToCreateProposal Member roles allowed to create the proposal
  /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
  /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
  /// @param _closingTime Vote closing time for Each voting layer
  /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  /// @param _contractAddress address of contract to call after proposal is accepted
  /// @param _contractName name of contract to be called after proposal is accepted
  /// @param _incentives rewards to distributed after proposal is accepted
  function addCategory(
    string calldata _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] calldata _allowedToCreateProposal,
    uint _closingTime,
    string calldata _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] calldata _incentives
  )
  external;

  /// @dev gets category details
  function category(uint _categoryId)
  external
  view
  returns (
    uint categoryId,
    uint memberRoleToVote,
    uint majorityVotePerc,
    uint quorumPerc,
    uint[] memory allowedToCreateProposal,
    uint closingTime,
    uint minStake
  );

  ///@dev gets category action details
  function categoryAction(uint _categoryId)
  external
  view
  returns (
    uint categoryId,
    address contractAddress,
    bytes2 contractName,
    uint defaultIncentive
  );

  /// @dev Gets Total number of categories added till now
  function totalCategories() external view returns (uint numberOfCategories);

  /// @dev Updates category details
  /// @param _categoryId Category id that needs to be updated
  /// @param _name Category name
  /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  /// @param _allowedToCreateProposal Member roles allowed to create the proposal
  /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
  /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
  /// @param _closingTime Vote closing time for Each voting layer
  /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  /// @param _contractAddress address of contract to call after proposal is accepted
  /// @param _contractName name of contract to be called after proposal is accepted
  /// @param _incentives rewards to distributed after proposal is accepted
  function updateCategory(
    uint _categoryId,
    string memory _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] memory _allowedToCreateProposal,
    uint _closingTime,
    string memory _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] memory _incentives
  )
  public;

}

