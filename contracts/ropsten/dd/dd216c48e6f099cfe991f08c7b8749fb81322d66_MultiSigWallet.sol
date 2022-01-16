/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.4.23;


interface DogKage{
    function transferOwner(address newOwner) external;
    function renounceOwnership() external;
    function setNewRouter(address newRouter) external;
    function setLpPair(address pair, bool enabled) external;
    function setExcludedFromFees(address account, bool enabled) external;
    function setTaxes(uint256 buyFee, uint256 sellFee, uint256 transferFee) external;
    function setRatios(uint256 liquidity, uint256 marketing) external;
    function setMaxTxPercent(uint256 percent, uint256 divisor) external;
    function setMaxWalletSize(uint256 percent, uint256 divisor) external;
    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external;
    function setWallets(address marketingWallet, address teamWallet) external;
    function setSwapAndLiquifyEnabled(bool _enabled) external;
}

contract MultiSigWallet{

    address ownerOne;
    address ownerTwo;
    address ownerThree;

    // Put Token Address here
    DogKage tokenInterface =  DogKage(0x6A7b82400f27032e9ecE78D2FE4d73257Dd4D555);

    constructor(address ownerOne_, address ownerTwo_, address ownerThree_) public {
        require(ownerOne_ != ownerTwo_ && ownerTwo_ != ownerThree_ && ownerThree_ != ownerOne_,"All three addresses must be unique");
        ownerOne=ownerOne_;
        ownerTwo=ownerTwo_;
        ownerThree=ownerThree_;
        
    }

    modifier onlyOwner(){
        require(msg.sender==ownerOne || msg.sender==ownerTwo || msg.sender==ownerThree,"Unauthorized");
        _;
    }



//=========================================================================================================//

    function changeOwnerOne(address newOwnerOne) public{
        require(msg.sender==ownerOne,"Unauthorized");
        ownerOne=newOwnerOne;
    }

    function changeOwnerTwo(address newOwnerTwo) public{
        require(msg.sender==ownerTwo,"Unauthorized");
        ownerTwo=newOwnerTwo;
    }

    function changeOwnerThree(address newOwnerThree) public{
        require(msg.sender==ownerThree,"Unauthorized");
        ownerThree=newOwnerThree;
    }


//=========================================================================================================//

    struct TransferOwnerProposal{
        address newOwner;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    TransferOwnerProposal[] transferOwnerProposals;
    uint256 numTransferOwnerProposals=0;

    function createTransferOwnerProposal(address newOwner) public onlyOwner{
        require(numTransferOwnerProposals==0 || transferOwnerProposals[numTransferOwnerProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        TransferOwnerProposal memory newProposal= TransferOwnerProposal({
            newOwner:newOwner,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numTransferOwnerProposals++;
        transferOwnerProposals.push(newProposal);
        
    }

    function voteTransferOwnerProposal(bool approve) public onlyOwner{
        require(numTransferOwnerProposals>=1,"No proposals yet");
        TransferOwnerProposal storage request = transferOwnerProposals[numTransferOwnerProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeTransferOwnerProposal(request.newOwner);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeTransferOwnerProposal(address newOwner) internal {
        tokenInterface.transferOwner(newOwner);
    }

    function viewTransferOwnerProposal() public view returns(address newOwner,uint256 votesYes, uint256 votesNo){
        if (numTransferOwnerProposals>=1){
            TransferOwnerProposal memory currentProposal = transferOwnerProposals[numTransferOwnerProposals-1];
            return (currentProposal.newOwner,currentProposal.votesYes,currentProposal.votesNo);
        }
    }



//=========================================================================================================//


    struct RenounceOwnershipProposal{
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    RenounceOwnershipProposal[] RenounceOwnershipProposals;
    uint256 numRenounceOwnershipProposals=0;

    function createRenounceOwnershipProposal() public onlyOwner{
        require(numRenounceOwnershipProposals==0 || RenounceOwnershipProposals[numRenounceOwnershipProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        RenounceOwnershipProposal memory newProposal= RenounceOwnershipProposal({
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numRenounceOwnershipProposals++;
        RenounceOwnershipProposals.push(newProposal);
        
    }

    function voteRenounceOwnershipProposal(bool approve) public onlyOwner{
        require(numRenounceOwnershipProposals>=1,"No proposals yet");
        RenounceOwnershipProposal storage request = RenounceOwnershipProposals[numRenounceOwnershipProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeRenounceOwnershipProposal();
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeRenounceOwnershipProposal() internal {
        tokenInterface.renounceOwnership();
    }

    function viewRenounceOwnershipProposal() public view returns(uint256 votesYes, uint256 votesNo){
        if (numRenounceOwnershipProposals>=1){
            RenounceOwnershipProposal memory currentProposal = RenounceOwnershipProposals[numRenounceOwnershipProposals-1];
            return (currentProposal.votesYes,currentProposal.votesNo);
        }
    }

    
//=========================================================================================================//


    struct SetNewRouterProposal{
        address newRouter;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetNewRouterProposal[] SetNewRouterProposals;
    uint256 numSetNewRouterProposals=0;

    function createSetNewRouterProposal(address newRouter) public onlyOwner{
        require(numSetNewRouterProposals==0 || SetNewRouterProposals[numSetNewRouterProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetNewRouterProposal memory newProposal= SetNewRouterProposal({
            newRouter:newRouter,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetNewRouterProposals++;
        SetNewRouterProposals.push(newProposal);
        
    }

    function voteSetNewRouterProposal(bool approve) public onlyOwner{
        require(numSetNewRouterProposals>=1,"No proposals yet");
        SetNewRouterProposal storage request = SetNewRouterProposals[numSetNewRouterProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetNewRouterProposal(request.newRouter);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetNewRouterProposal(address newRouter) internal {
        tokenInterface.setNewRouter(newRouter);
    }

    function viewSetNewRouterProposal() public view returns(address newRouter,uint256 votesYes, uint256 votesNo){
        if (numSetNewRouterProposals>=1){
            SetNewRouterProposal memory currentProposal = SetNewRouterProposals[numSetNewRouterProposals-1];
            return (currentProposal.newRouter,currentProposal.votesYes,currentProposal.votesNo);
        }
    }

//=========================================================================================================//


    struct SetLPPairProposal{
        address pair;
        bool enabled;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetLPPairProposal[] SetLPPairProposals;
    uint256 numSetLPPairProposals=0;

    function createSetLPPairProposal(address pair, bool enabled) public onlyOwner{
        require(numSetLPPairProposals==0 || SetLPPairProposals[numSetLPPairProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetLPPairProposal memory newProposal= SetLPPairProposal({
            pair:pair,
            enabled:enabled,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetLPPairProposals++;
        SetLPPairProposals.push(newProposal);
        
    }

    function voteSetLPPairProposal(bool approve) public onlyOwner{
        require(numSetLPPairProposals>=1,"No proposals yet");
        SetLPPairProposal storage request = SetLPPairProposals[numSetLPPairProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetLPPairProposal(request.pair, request.enabled);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetLPPairProposal(address pair, bool enabled) internal {
        tokenInterface.setLpPair(pair, enabled);
    }

    function viewSetLPPairProposal() public view returns(address pair,bool enabled,uint256 votesYes, uint256 votesNo){
        if (numSetLPPairProposals>=1){
            SetLPPairProposal memory currentProposal = SetLPPairProposals[numSetLPPairProposals-1];
            return (currentProposal.pair,currentProposal.enabled,currentProposal.votesYes,currentProposal.votesNo);
        }
    }

//=========================================================================================================//


    struct SetExcludedFromFeesProposal{
        address account;
        bool enabled;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetExcludedFromFeesProposal[] SetExcludedFromFeesProposals;
    uint256 numSetExcludedFromFeesProposals=0;

    function createSetExcludedFromFeesProposal(address account, bool enabled) public onlyOwner{
        require(numSetExcludedFromFeesProposals==0 || SetExcludedFromFeesProposals[numSetExcludedFromFeesProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetExcludedFromFeesProposal memory newProposal= SetExcludedFromFeesProposal({
            account:account,
            enabled:enabled,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetExcludedFromFeesProposals++;
        SetExcludedFromFeesProposals.push(newProposal);
        
    }

    function voteSetExcludedFromFeesProposal(bool approve) public onlyOwner{
        require(numSetExcludedFromFeesProposals>=1,"No proposals yet");
        SetExcludedFromFeesProposal storage request = SetExcludedFromFeesProposals[numSetExcludedFromFeesProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetExcludedFromFeesProposal(request.account, request.enabled);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetExcludedFromFeesProposal(address account, bool enabled) internal {
        tokenInterface.setExcludedFromFees(account, enabled);
    }

    function viewSetExcludedFromFeesProposal() public view returns(address account, bool enabled,uint256 votesYes, uint256 votesNo){
        if (numSetExcludedFromFeesProposals>=1){
            SetExcludedFromFeesProposal memory currentProposal = SetExcludedFromFeesProposals[numSetExcludedFromFeesProposals-1];
            return (currentProposal.account,currentProposal.enabled,currentProposal.votesYes,currentProposal.votesNo);
        }
    }


//=========================================================================================================//

    struct SetTaxesProposal{
        uint256 buyFee;
        uint256 sellFee;
        uint256 transferFee;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetTaxesProposal[] SetTaxesProposals;
    uint256 numSetTaxesProposals=0;

    function createSetTaxesProposal(uint256 buyFee, uint256 sellFee, uint256 transferFee) public onlyOwner{
        require(numSetTaxesProposals==0 || SetTaxesProposals[numSetTaxesProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetTaxesProposal memory newProposal= SetTaxesProposal({
            buyFee:buyFee,
            sellFee:sellFee,
            transferFee:transferFee,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetTaxesProposals++;
        SetTaxesProposals.push(newProposal);
        
    }

    function voteSetTaxesProposal(bool approve) public onlyOwner{
        require(numSetTaxesProposals>=1,"No proposals yet");
        SetTaxesProposal storage request = SetTaxesProposals[numSetTaxesProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetTaxesProposal(request.buyFee,request.sellFee,request.transferFee);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetTaxesProposal(uint256 buyFee, uint256 sellFee, uint256 transferFee) internal {
        tokenInterface.setTaxes(buyFee, sellFee, transferFee);
    }

    function viewSetTaxesProposal() public view returns(uint256 buyFee, uint256 sellFee, uint256 transferFee,uint256 votesYes, uint256 votesNo){
        if (numSetTaxesProposals>=1){
            SetTaxesProposal memory currentProposal = SetTaxesProposals[numSetTaxesProposals-1];
            return (currentProposal.buyFee,currentProposal.sellFee,currentProposal.transferFee,currentProposal.votesYes,currentProposal.votesNo);
        }
    }


//=========================================================================================================//


    struct SetRatiosProposal{
        uint256 liquidity;
        uint256 marketing;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetRatiosProposal[] SetRatiosProposals;
    uint256 numSetRatiosProposals=0;

    function createSetRatiosProposal(uint256 liquidity, uint256 marketing) public onlyOwner{
        require(numSetRatiosProposals==0 || SetRatiosProposals[numSetRatiosProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetRatiosProposal memory newProposal= SetRatiosProposal({
            liquidity:liquidity,
            marketing:marketing,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetRatiosProposals++;
        SetRatiosProposals.push(newProposal);
        
    }

    function voteSetRatiosProposal(bool approve) public onlyOwner{
        require(numSetRatiosProposals>=1,"No proposals yet");
        SetRatiosProposal storage request = SetRatiosProposals[numSetRatiosProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetRatiosProposal(request.liquidity,request.marketing);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetRatiosProposal(uint256 liquidity, uint256 marketing) internal {
        tokenInterface.setRatios(liquidity, marketing);
    }

    function viewSetRatiosProposal() public view returns(uint256 liquidity, uint256 marketing,uint256 votesYes, uint256 votesNo){
        if (numSetRatiosProposals>=1){
            SetRatiosProposal memory currentProposal = SetRatiosProposals[numSetRatiosProposals-1];
            return (currentProposal.liquidity,currentProposal.marketing,currentProposal.votesYes,currentProposal.votesNo);
        }
    }

//=========================================================================================================//

    struct SetMaxTxPercentProposal{
        uint256 percent;
        uint256 divisor;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetMaxTxPercentProposal[] SetMaxTxPercentProposals;
    uint256 numSetMaxTxPercentProposals=0;

    function createSetMaxTxPercentProposal(uint256 percent, uint256 divisor) public onlyOwner{
        require(numSetMaxTxPercentProposals==0 || SetMaxTxPercentProposals[numSetMaxTxPercentProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetMaxTxPercentProposal memory newProposal= SetMaxTxPercentProposal({
            percent:percent,
            divisor:divisor,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetMaxTxPercentProposals++;
        SetMaxTxPercentProposals.push(newProposal);
        
    }

    function voteSetMaxTxPercentProposal(bool approve) public onlyOwner{
        require(numSetMaxTxPercentProposals>=1,"No proposals yet");
        SetMaxTxPercentProposal storage request = SetMaxTxPercentProposals[numSetMaxTxPercentProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetMaxTxPercentProposal(request.percent,request.divisor);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetMaxTxPercentProposal(uint256 percent, uint256 divisor) internal {
        tokenInterface.setMaxTxPercent(percent, divisor);
    }

    function viewSetMaxTxPercentProposal() public view returns(uint256 percent, uint256 divisor,uint256 votesYes, uint256 votesNo){
        if (numSetMaxTxPercentProposals>=1){
            SetMaxTxPercentProposal memory currentProposal = SetMaxTxPercentProposals[numSetMaxTxPercentProposals-1];
            return (currentProposal.percent,currentProposal.divisor,currentProposal.votesYes,currentProposal.votesNo);
        }
    }


//=========================================================================================================//

    struct SetMaxWalletSizeProposal{
        uint256 percent;
        uint256 divisor;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetMaxWalletSizeProposal[] SetMaxWalletSizeProposals;
    uint256 numSetMaxWalletSizeProposals=0;

    function createSetMaxWalletSizeProposal(uint256 percent, uint256 divisor) public onlyOwner{
        require(numSetMaxWalletSizeProposals==0 || SetMaxWalletSizeProposals[numSetMaxWalletSizeProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetMaxWalletSizeProposal memory newProposal= SetMaxWalletSizeProposal({
            percent:percent,
            divisor:divisor,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetMaxWalletSizeProposals++;
        SetMaxWalletSizeProposals.push(newProposal);
        
    }

    function voteSetMaxWalletSizeProposal(bool approve) public onlyOwner{
        require(numSetMaxWalletSizeProposals>=1,"No proposals yet");
        SetMaxWalletSizeProposal storage request = SetMaxWalletSizeProposals[numSetMaxWalletSizeProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetMaxWalletSizeProposal(request.percent,request.divisor);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetMaxWalletSizeProposal(uint256 percent, uint256 divisor) internal {
        tokenInterface.setMaxWalletSize(percent, divisor);
    }

    function viewSetMaxWalletSizeProposal() public view returns(uint256 percent, uint256 divisor,uint256 votesYes, uint256 votesNo){
        if (numSetMaxWalletSizeProposals>=1){
            SetMaxWalletSizeProposal memory currentProposal = SetMaxWalletSizeProposals[numSetMaxWalletSizeProposals-1];
            return (currentProposal.percent,currentProposal.divisor,currentProposal.votesYes,currentProposal.votesNo);
        }
    }


//=========================================================================================================//


    struct SetWalletsProposal{
        address marketingWallet;
        address teamWallet;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetWalletsProposal[] SetWalletsProposals;
    uint256 numSetWalletsProposals=0;

    function createSetWalletsProposal(address marketingWallet, address teamWallet) public onlyOwner{
        require(numSetWalletsProposals==0 || SetWalletsProposals[numSetWalletsProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetWalletsProposal memory newProposal= SetWalletsProposal({
            marketingWallet:marketingWallet,
            teamWallet:teamWallet,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetWalletsProposals++;
        SetWalletsProposals.push(newProposal);
        
    }

    function voteSetWalletsProposal(bool approve) public onlyOwner{
        require(numSetWalletsProposals>=1,"No proposals yet");
        SetWalletsProposal storage request = SetWalletsProposals[numSetWalletsProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetWalletsProposal(request.marketingWallet,request.teamWallet);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetWalletsProposal(address marketingWallet, address teamWallet) internal {
        tokenInterface.setWallets(marketingWallet, teamWallet);
    }

    function viewSetWalletsProposal() public view returns(address marketingWallet, address teamWallet,uint256 votesYes, uint256 votesNo){
        if (numSetWalletsProposals>=1){
            SetWalletsProposal memory currentProposal = SetWalletsProposals[numSetWalletsProposals-1];
            return (currentProposal.marketingWallet,currentProposal.teamWallet,currentProposal.votesYes,currentProposal.votesNo);
        }
    }


//=========================================================================================================//


    struct SetSwapAndLiquifyProposal{
        bool enabled;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetSwapAndLiquifyProposal[] SetSwapAndLiquifyProposals;
    uint256 numSetSwapAndLiquifyProposals=0;

    function createSetSwapAndLiquifyProposal(bool enabled) public onlyOwner{
        require(numSetSwapAndLiquifyProposals==0 || SetSwapAndLiquifyProposals[numSetSwapAndLiquifyProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetSwapAndLiquifyProposal memory newProposal= SetSwapAndLiquifyProposal({
            enabled:enabled,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetSwapAndLiquifyProposals++;
        SetSwapAndLiquifyProposals.push(newProposal);
        
    }

    function voteSetSwapAndLiquifyProposal(bool approve) public onlyOwner{
        require(numSetSwapAndLiquifyProposals>=1,"No proposals yet");
        SetSwapAndLiquifyProposal storage request = SetSwapAndLiquifyProposals[numSetSwapAndLiquifyProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetSwapAndLiquifyProposal(request.enabled);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetSwapAndLiquifyProposal(bool enabled) internal {
        tokenInterface.setSwapAndLiquifyEnabled(enabled);
    }

    function viewSetSwapAndLiquifyProposal() public view returns(bool enabled,uint256 votesYes, uint256 votesNo){
        if (numSetSwapAndLiquifyProposals>=1){
            SetSwapAndLiquifyProposal memory currentProposal = SetSwapAndLiquifyProposals[numSetSwapAndLiquifyProposals-1];
            return (currentProposal.enabled,currentProposal.votesYes,currentProposal.votesNo);
        }
    }


//=========================================================================================================//


    struct SetSwapSettingsProposal{
        uint256 thresholdPercent;
        uint256 thresholdDivisor;
        uint256 amountPercent;
        uint256 amountDivisor;
        bool complete;
        uint256 votesYes;
        uint256 votesNo;
        mapping(address=>bool) approvals;
    }

    SetSwapSettingsProposal[] SetSwapSettingsProposals;
    uint256 numSetSwapSettingsProposals=0;

    function createSetSwapSettingsProposal(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) public onlyOwner{
        require(numSetSwapSettingsProposals==0 || SetSwapSettingsProposals[numSetSwapSettingsProposals-1].complete == true,"Pending proposal, please complete voting on that one first");
        SetSwapSettingsProposal memory newProposal= SetSwapSettingsProposal({
            thresholdPercent:thresholdPercent,
            thresholdDivisor:thresholdDivisor,
            amountPercent:amountPercent,
            amountDivisor:amountDivisor,
            complete:false,
            votesYes:0,
            votesNo:0
        });
        numSetSwapSettingsProposals++;
        SetSwapSettingsProposals.push(newProposal);
    }

    function voteSetSwapSettingsProposal(bool approve) public onlyOwner{
        require(numSetSwapSettingsProposals>=1,"No proposals yet");
        SetSwapSettingsProposal storage request = SetSwapSettingsProposals[numSetSwapSettingsProposals-1];
        require(!request.complete,"No pending proposals");
        require(!request.approvals[msg.sender],"Already Voted");
        request.approvals[msg.sender]=true;
        if(approve){
            request.votesYes++;
        }
        else{
            request.votesNo++;
        }
        if (request.votesYes>=2){
            request.complete=true;
            _finalizeSetSwapSettingsProposal(request.thresholdPercent,request.thresholdDivisor,request.amountPercent,request.amountDivisor);
        }
        else if(request.votesNo>=2){
            request.complete=true;
        }
    }

    function _finalizeSetSwapSettingsProposal(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) internal {
        tokenInterface.setSwapSettings(thresholdPercent, thresholdDivisor, amountPercent, amountDivisor);
    }

    function viewSetSwapSettingsProposal() public view returns(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor,uint256 votesYes, uint256 votesNo){
        if (numSetSwapSettingsProposals>=1){
            SetSwapSettingsProposal memory currentProposal = SetSwapSettingsProposals[numSetSwapSettingsProposals-1];
            return (currentProposal.thresholdPercent,currentProposal.thresholdDivisor,currentProposal.amountPercent,currentProposal.amountDivisor,currentProposal.votesYes,currentProposal.votesNo);
        }
    }

}