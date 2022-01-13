/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity 0.6.7;

abstract contract Auth {
  function addAuthorization(address) public virtual;
  function removeAuthorization(address) public virtual;
}

abstract contract Setter is Auth {
  function modifyParameters(bytes32, address) public virtual;
  function addFundedFunction(address, bytes4, uint) public virtual;
  function removeFundedFunction(address, bytes4) public virtual;
  function addFundingReceiver(address, bytes4, uint, uint, uint, uint) public virtual;
  function removeFundingReceiver(address, bytes4) public virtual;
  function toggleReimburser(address) public virtual;
  function modifyParameters(bytes32, uint256, uint256, bytes4, address) public virtual;
}

contract Proposal {
  function execute(bool) public {
    address deployer = 0x3E0139cE3533a42A7D342841aEE69aB2BfEE1d51;

    // Swapping the surplus auction house
    Setter accountingEngine = Setter(0xcEe6Aa1aB47d0Fb0f24f51A3072EC16E20F90fcE);
    Setter newSurplusAuctionHouse = Setter(0x4EEfDaE928ca97817302242a851f317Be1B85C90);
    Setter newAutoSurplusBuffer = Setter(0x9fe16154582ecCe3414536FdE57A201c17398b2A);
    Setter newAutoSurplusBufferOverlay = Setter(0x7A2414F6b6Ee5D4a043E26127f29ca6D65ea31cd);
    // set surplus auction house on accounting engine
    accountingEngine.modifyParameters("surplusAuctionHouse", address(newSurplusAuctionHouse));

    // auth accounting engine on surplus auction house
    newSurplusAuctionHouse.addAuthorization(address(accountingEngine));
    // deauth deployer
    newSurplusAuctionHouse.removeAuthorization(deployer);
    // add prot receiver GEB_STAKING_REWARD_ADJUSTER
    newSurplusAuctionHouse.modifyParameters("protocolTokenBidReceiver", 0x03da3D5E0b13b6f0917FA9BC3d65B46229d7Ef47);


    // Swapping the auto surplus buffer
    // auth in accounting engine
    accountingEngine.addAuthorization(address(newAutoSurplusBuffer));

    // deauth old auto surplus buffer in accounting engine
    accountingEngine.removeAuthorization(0x1450f40E741F2450A95F9579Be93DD63b8407a25); // old GEB_AUTO_SURPLUS_BUFFER

    // auth INCREASING_TREASURY_REIMBURSEMENT_OVERLAY on auto surplus buffer
    newAutoSurplusBuffer.addAuthorization(0x1dCeE093a7C952260f591D9B8401318f2d2d72Ac);
    Setter(0x1dCeE093a7C952260f591D9B8401318f2d2d72Ac).toggleReimburser(address(newAutoSurplusBuffer));
    Setter(0x1dCeE093a7C952260f591D9B8401318f2d2d72Ac).toggleReimburser(0x1450f40E741F2450A95F9579Be93DD63b8407a25); // old GEB_AUTO_SURPLUS_BUFFER

    // auth new AUTO_SURPLUS_BUFFER_SETTER_OVERLAY
    newAutoSurplusBuffer.addAuthorization(address(newAutoSurplusBufferOverlay));

    // deauth deployer
    newAutoSurplusBuffer.removeAuthorization(deployer);

    // remove deployer auth from new overlay
    newAutoSurplusBufferOverlay.removeAuthorization(deployer);

    // authing GEB_MINMAX_REWARDS_ADJUSTER
    newAutoSurplusBuffer.addAuthorization(0xa937A6da2837Dcc91eB19657b051504C0D512a35);

    // add/remove old from GEB_TREASURY_CORE_PARAM_ADJUSTER, adjustSurplusBuffer(address), current latestExpectedCalls
    Setter(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787).addFundedFunction(address(newAutoSurplusBuffer), 0xbf1ad0db, 26);
    Setter(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787).removeFundedFunction(0x1450f40E741F2450A95F9579Be93DD63b8407a25, 0xbf1ad0db);

    // add/remove old from GEB_MINMAX_REWARDS_ADJUSTER, same params
    Setter(0xa937A6da2837Dcc91eB19657b051504C0D512a35).addFundingReceiver(address(newAutoSurplusBuffer), 0xbf1ad0db, 86400, 1000, 100, 200);
    Setter(0xa937A6da2837Dcc91eB19657b051504C0D512a35).removeFundingReceiver(0x1450f40E741F2450A95F9579Be93DD63b8407a25, 0xbf1ad0db);

    // adding new contract to GEB_REWARD_ADJUSTER_BUNDLER
    Setter(0x7F55e74C25647c100256D87629dee379D68bdCDe).modifyParameters("addFunction", 0, 1, bytes4(0xbf1ad0db), address(newAutoSurplusBuffer));

    // removing old contract from GEB_REWARD_ADJUSTER_BUNDLER
    Setter(0x7F55e74C25647c100256D87629dee379D68bdCDe).modifyParameters("removeFunction", 9, 1, 0x0, address(0));
  }
}