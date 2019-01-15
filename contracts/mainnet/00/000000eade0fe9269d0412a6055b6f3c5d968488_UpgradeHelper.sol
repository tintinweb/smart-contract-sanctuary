pragma solidity ^0.4.23;

// File: contracts/utilities/UpgradeHelper.sol

contract OldTrueUSDInterface {
    function delegateToNewContract(address _newContract) public;
    function claimOwnership() public;
    function balances() public returns(address);
    function allowances() public returns(address);
    function totalSupply() public returns(uint);
    function transferOwnership(address _newOwner) external;
}
contract NewTrueUSDInterface {
    function setTotalSupply(uint _totalSupply) public;
    function transferOwnership(address _newOwner) public;
    function claimOwnership() public;
}

contract TokenControllerInterface {
    function claimOwnership() external;
    function transferChild(address _child, address _newOwner) external;
    function requestReclaimContract(address _child) external;
    function issueClaimOwnership(address _child) external;
    function setTrueUSD(address _newTusd) external;
    function setTusdRegistry(address _Registry) external;
    function claimStorageForProxy(address _delegate,
        address _balanceSheet,
        address _alowanceSheet) external;
    function setGlobalPause(address _globalPause) external;
    function transferOwnership(address _newOwner) external;
    function owner() external returns(address);
}

/**
 */
contract UpgradeHelper {
    OldTrueUSDInterface public constant oldTrueUSD = OldTrueUSDInterface(0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E);
    NewTrueUSDInterface public constant newTrueUSD = NewTrueUSDInterface(0x0000000000085d4780B73119b644AE5ecd22b376);
    TokenControllerInterface public constant tokenController = TokenControllerInterface(0x0000000000075EfBeE23fe2de1bd0b7690883cc9);
    address public constant registry = address(0x0000000000013949F288172bD7E36837bDdC7211);
    address public constant globalPause = address(0x0000000000027f6D87be8Ade118d9ee56767d993);

    function upgrade() public {
        // TokenController should have end owner as it&#39;s pending owner at the end
        address endOwner = tokenController.owner();

        // Helper contract becomes the owner of controller, and both TUSD contracts
        tokenController.claimOwnership();
        newTrueUSD.claimOwnership();

        // Initialize TrueUSD totalSupply
        newTrueUSD.setTotalSupply(oldTrueUSD.totalSupply());

        // Claim storage contract from oldTrueUSD
        address balanceSheetAddress = oldTrueUSD.balances();
        address allowanceSheetAddress = oldTrueUSD.allowances();
        tokenController.requestReclaimContract(balanceSheetAddress);
        tokenController.requestReclaimContract(allowanceSheetAddress);

        // Transfer storage contract to controller then transfer it to NewTrueUSD
        tokenController.issueClaimOwnership(balanceSheetAddress);
        tokenController.issueClaimOwnership(allowanceSheetAddress);
        tokenController.transferChild(balanceSheetAddress, newTrueUSD);
        tokenController.transferChild(allowanceSheetAddress, newTrueUSD);
        
        newTrueUSD.transferOwnership(tokenController);
        tokenController.issueClaimOwnership(newTrueUSD);
        tokenController.setTrueUSD(newTrueUSD);
        tokenController.claimStorageForProxy(newTrueUSD, balanceSheetAddress, allowanceSheetAddress);

        // Configure TrueUSD
        tokenController.setTusdRegistry(registry);
        tokenController.setGlobalPause(globalPause);

        // Point oldTrueUSD delegation to NewTrueUSD
        tokenController.transferChild(oldTrueUSD, address(this));
        oldTrueUSD.claimOwnership();
        oldTrueUSD.delegateToNewContract(newTrueUSD);
        
        // Controller owns both old and new TrueUSD
        oldTrueUSD.transferOwnership(tokenController);
        tokenController.issueClaimOwnership(oldTrueUSD);
        tokenController.transferOwnership(endOwner);
    }
}