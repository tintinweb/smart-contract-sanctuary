/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity 0.5.4;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract ERC20 {
  function transfer(address to, uint256 value) public returns (bool);
}

contract MultiSign {
    using SafeMath for uint;
    
    address public ThirdParty = address(0x9E832A9CEaDf1E97D6d8da6922b87b59d25eEee0);
    address public Foundation = address(0x031DE0f3C1D4e525baBa97829eccb3d3D66E9bdb);
    uint256 public ProposalID = 0;
    mapping(uint => Proposal) public Proposals;

    struct Proposal {
        uint256 id;                   // proposal id
        address to;                   // to address
        bool close;                   // false open, true close
        address tokenContractAddress; // ERC20 token contract address
        uint256 amount;               // token amount
        uint256 approvalByThirdParty; // default: 0 approval: 1 refuse: 2
        uint256 approvalByFoundation; // default: 0 approval: 1 refuse: 2
    }
    
    
    constructor() public {
    }
    
    function lookProposal(uint256 id) public view returns (uint256 _id, address _to, bool _close, address _tokenContractAddress, uint256 _amount, uint256 _approvalByThirdParty, uint256 _approvalByFoundation) {
        Proposal memory p = Proposals[id];
        return (p.id, p.to, p.close, p.tokenContractAddress, p.amount, p.approvalByThirdParty, p.approvalByFoundation);
    }
    
    // only  Foundation or ThirdParty can proposal
    function proposal (address _to, address _tokenContractAddress, uint256 _amount) public returns (uint256 id) {
        require(msg.sender == Foundation || msg.sender == ThirdParty);
        ProposalID = ProposalID.add(1);
        Proposals[ProposalID] = Proposal(ProposalID, _to, false, _tokenContractAddress, _amount, 0, 0);
        return id;
    }
    
    // only  Foundation or ThirdParty can approval
    function approval (uint256 id) public returns (bool) {
        require(msg.sender == Foundation || msg.sender == ThirdParty);
        Proposal storage p = Proposals[id];
        require(p.close == false);
        if (msg.sender == Foundation && p.approvalByFoundation == 0) {
            p.approvalByFoundation = 1;
            Proposals[id] = p;
        }
        if (msg.sender == ThirdParty && p.approvalByThirdParty == 0) {
            p.approvalByThirdParty = 1;
            Proposals[id] = p;
        }
        
        if (p.approvalByThirdParty == 1 && p.approvalByFoundation == 1) {
            p.close = true;
            Proposals[id] = p;
            require(ERC20(p.tokenContractAddress).transfer(p.to, p.amount.mul(1e18)));
        }
        return true;
    }
    
    // only  Foundation or ThirdParty can refuse
    function refuse (uint256 id) public returns (bool) {
        require(msg.sender == Foundation || msg.sender == ThirdParty);
        Proposal storage p = Proposals[id];
        require(p.close == false);
        require(p.approvalByFoundation == 0 || p.approvalByThirdParty == 0);
        
        if (msg.sender == Foundation && p.approvalByFoundation == 0) {
            p.close = true;
            p.approvalByFoundation = 2;
            Proposals[id] = p;
            return true;
        }
        if (msg.sender == ThirdParty && p.approvalByThirdParty == 0) {
            p.close = true;
            p.approvalByThirdParty = 2;
            Proposals[id] = p;
            return true;
        }
        return true;
    }
    
    
    function() payable external {
        revert();
    }
}