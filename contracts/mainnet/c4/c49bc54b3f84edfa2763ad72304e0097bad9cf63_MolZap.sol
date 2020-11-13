/*
███╗   ███╗ ██████╗ ██╗      
████╗ ████║██╔═══██╗██║    
██╔████╔██║██║   ██║██║    
██║╚██╔╝██║██║   ██║██║    
██║ ╚═╝ ██║╚██████╔╝███████╗
███████╗ █████╗ ██████╗                              
╚══███╔╝██╔══██╗██╔══██╗                             
  ███╔╝ ███████║██████╔╝                             
 ███╔╝  ██╔══██║██╔═══╝                              
███████╗██║  ██║██║
DEAR MSG.SENDER(S):
/ MolZap (⚡👹⚡) is a project in beta.
// Please audit and use at your own risk.
/// STEAL THIS C0D3SL4W 
//// presented by LexDAO LLC
*/
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.4;

interface IERC20ApproveTransfer { // brief interface for erc20 token tx
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IMoloch { // brief interface for txs to moloch dao
    function cancelProposal(uint256 proposalId) external;
    
    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);
    
    function withdrawBalance(address token, uint256 amount) external;
}

library SafeMath { // arithmetic wrapper for unit under/overflow check
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}

contract MolZap {
    using SafeMath for uint256;
    
    address public manager; // manages moloch zap settings
    address public moloch; // parent moloch for zap proposals 
    address public wETH; // ether token wrapper contract reference for proposals
    uint256 public zapRate; // rate to convert ether into zap proposal shares (e.g., `10` will submit proposal for 10 shares per 1 ETH sent)
    string public ZAP_DETAILS; // general zap proposal details 

    mapping(uint256 => Zap) public zaps; // proposalId => Zap
    
    struct Zap {
        address proposer;
        uint256 zapAmount;
    }

    event ProposeZap(address indexed proposer, uint256 proposalId);
    event WithdrawZapProposal(address indexed proposer, uint256 proposalId);
    event UpdateMolZap(address indexed manager, address indexed moloch, address indexed wETH, uint256 zapRate, string ZAP_DETAILS);

    constructor(
        address _manager, 
        address _moloch, 
        address _wETH, 
        uint256 _zapRate, 
        string memory _ZAP_DETAILS
    ) {
        manager = _manager;
        moloch = _moloch;
        wETH = _wETH;
        zapRate = _zapRate;
        ZAP_DETAILS = _ZAP_DETAILS;
        IERC20ApproveTransfer(wETH).approve(moloch, uint256(-1));
    }
    
    receive() external payable { // msg.sender ether submits share proposal to moloch per zap rate (adjusted for wei conversion to normal moloch amounts)
        (bool success, ) = wETH.call{value: msg.value}("");
        require(success, "MolZap::transfer failed");
        
        uint256 proposalId = IMoloch(moloch).submitProposal(
            msg.sender,
            msg.value.mul(zapRate).div(10**18),
            0,
            msg.value,
            wETH,
            0,
            wETH,
            ZAP_DETAILS
        );
        
        zaps[proposalId] = Zap(msg.sender, msg.value);

        emit ProposeZap(msg.sender, proposalId);
    }
    
    function cancelZapProposal(uint256 proposalId) external { // zap proposer can cancel zap & withdraw proposal funds 
        Zap storage zap = zaps[proposalId];
        require(msg.sender == zap.proposer, "MolZap::!proposer");
        uint256 zapAmount = zap.zapAmount;
        
        IMoloch(moloch).cancelProposal(proposalId); // cancel zap proposal in parent moloch
        IMoloch(moloch).withdrawBalance(wETH, zapAmount); // withdraw zap funds from moloch
        IERC20ApproveTransfer(wETH).transfer(msg.sender, zapAmount); // redirect funds to zap proposer
        
        emit WithdrawZapProposal(msg.sender, proposalId);
    }
    
    function drawZapProposal(uint256 proposalId) external { // if proposal fails, withdraw back to proposer
        Zap storage zap = zaps[proposalId];
        require(msg.sender == zap.proposer, "MolZap::!proposer");
        uint256 zapAmount = zap.zapAmount;
        
        IMoloch(moloch).withdrawBalance(wETH, zapAmount); // withdraw zap funds from parent moloch
        IERC20ApproveTransfer(wETH).transfer(msg.sender, zapAmount); // redirect funds to zap proposer
        
        emit WithdrawZapProposal(msg.sender, proposalId);
    }
    
    function updateMolZap( // manager (e.g., moloch via adminion) adjusts zap proposal settings
        address _manager, 
        address _moloch, 
        address _wETH, 
        uint256 _zapRate, 
        string calldata _ZAP_DETAILS
    ) external { 
        require(msg.sender == manager, "MolZap::!manager");
       
        manager = _manager;
        moloch = _moloch;
        wETH = _wETH;
        zapRate = _zapRate;
        ZAP_DETAILS = _ZAP_DETAILS;
        
        emit UpdateMolZap(_manager, _moloch, _wETH, _zapRate, _ZAP_DETAILS);
    }
}