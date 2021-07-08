/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-19
*/

pragma solidity ^0.5;

contract owned {
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
         require(msg.sender == owner,"only owner method");
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract limited is owned {
    mapping (address => bool) canAsk;
    
    
     modifier onlyCanAsk {
        require(canAsk[msg.sender]);
        _;
    }
    
    
    
    function changeAsk (address a,bool allow) onlyOwner public {
        canAsk[a] = allow;
    }
    
}

interface ICampaign {
    
    function update(bytes32 idRequest,uint64 likes,uint64 shares,uint64 views) external  returns (bool ok);
    function updateBounty(bytes32 idProm,uint256 nbAbos) external  returns (bool ok);
}

interface IERC20 {
   function transfer(address _to, uint256 _value) external;
}

contract oracle is limited {
    
    struct oracleUnit {
        bool granted;
	    address token;
	    uint256 fee;
	}
    
    mapping (address => oracleUnit) oracleList;
    
     modifier onlyCanAnswer {
        require(oracleList[msg.sender].granted || msg.sender == owner,"sender not in whitelist");
        _;
    }
    
    function changeAnswer (address a,bool allow,address token,uint256 fee) onlyOwner public {
        oracleList[a] = oracleUnit(allow,token,fee);
    }
    // social network ids: 
    // 01 : facebook;
    // 02 : youtube
    // 03 : instagram
    // 04 : twitter
 
    
    event AskRequest(bytes32 indexed idRequest, uint8 typeSN, string idPost,string idUser);
    event AnswerRequest(bytes32 indexed idRequest, uint64 likes, uint64 shares, uint64 views);
    
    event AskRequestBounty( uint8 typeSN, string idPost,string idUser,bytes32 idProm);
    event AnswerRequestBounty(bytes32 indexed idProm,uint256 nbAbos);
   
    
    function  ask (uint8 typeSN,string memory idPost,string memory idUser, bytes32 idRequest) public onlyCanAsk
    {
        emit AskRequest(idRequest, typeSN, idPost, idUser );
    }
    
    function askBounty(uint8 typeSN,string memory idPost,string memory idUser, bytes32 idProm) public onlyCanAsk
    {
        emit AskRequestBounty( typeSN, idPost, idUser, idProm);
    }
    
    function answer(address campaignContract,bytes32 idRequest,uint64 likes,uint64 shares, uint64 views) public onlyOwner {
        ICampaign campaign = ICampaign(campaignContract);
        campaign.update(idRequest,likes,shares,views);
        emit AnswerRequest(idRequest,likes,shares,views);
    }
    
    function answerBounty(address campaignContract,bytes32 idProm,uint256 nbAbos) public onlyOwner {
        ICampaign campaign = ICampaign(campaignContract);
        campaign.updateBounty(idProm,nbAbos);
        emit AnswerRequestBounty(idProm,nbAbos);
    }
    
    
     function thirdPartyAnswer(address campaignContract,bytes32 idRequest,uint64 likes,uint64 shares, uint64 views) public onlyCanAnswer {
        ICampaign campaign = ICampaign(campaignContract);
        campaign.update(idRequest,likes,shares,views);
        emit AnswerRequest(idRequest,likes,shares,views);
        
    
        IERC20 erc20 = IERC20(oracleList[msg.sender].token);
        erc20.transfer(msg.sender,oracleList[msg.sender].fee);
     }
     
     function oracleFee(address u) public returns ( uint256 f){
         return 0;
     }
    
    
    function() external payable {}
    
    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    function transferToken (address token,address to,uint256 val) public onlyOwner {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(to,val);
    }
    
}