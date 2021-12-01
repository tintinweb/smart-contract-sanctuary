/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8;


abstract contract owned {
    address payable public owner;

    constructor ()  {
        owner =  payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner,"only owner method");
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface IERC20 {
    
   function transfer(address _to, uint256 _value) external;
   function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
   
}

abstract contract ERC20Holder is owned {
    mapping (address => bool) acceptedTokens;
    function modToken(address token,bool accepted) public onlyOwner {
        acceptedTokens[token] = accepted;
    }
    
    function tokenFallback(address _from, uint _value, bytes memory _data) pure public returns (bytes32 hash) {
        bytes32 tokenHash = keccak256(abi.encodePacked(_from,_value,_data));
        return tokenHash;
    }
    
    fallback() external  payable {}
    
    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    function transferToken (address token,address to,uint256 val) public onlyOwner {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(to,val);
    }
    
}

contract oracleClient is ERC20Holder {
    
    address oracle;
    
    function setOracle(address a) public  onlyOwner {
        
        oracle = a;
    }
}

interface IOracle {
    function  ask (uint8 typeSN, string calldata idPost,string calldata idUser, bytes32 idRequest) external;
    function  askBounty (uint8 typeSN, string calldata idPost,string calldata idUser, bytes32 idProm) external;
    function oracleFee(address who)  external returns (uint256 fee);
}


contract campaign is oracleClient {
    
    struct cpRatio {
        uint256 likeRatio;
        uint256 shareRatio;
        uint256 viewRatio;
        uint256 reachLimit;
    }
    
    struct bountyUnit {
        uint256 minRange;
        uint256 maxRange;
        uint256 typeSN;
        uint256 amount;
    }
    
    struct Campaign {
		address advertiser;
		string dataUrl; 
		uint64 startDate;
		uint64 endDate;
		uint64 nbProms;
		uint64 nbValidProms;
		mapping (uint64 => bytes32)  proms;
		Fund funds;
		mapping(uint8 => cpRatio)  ratios;
		bountyUnit[] bounties;
	}
	
	 struct OracleUnit {
		address advertiser;
		Fund funds;
	}
	
	struct Fund {
	    address token;
	    uint256 amount;
	}
	
	struct Result  {
	    bytes32 idProm;
	    uint64 likes;
	    uint64 shares;
	    uint64 views;
	}
	
	struct promElement {
	    address influencer;
	    bytes32 idCampaign;
	    bool isAccepted;
	    bool isPayed;
	    Fund funds;
	    uint8 typeSN;
	    string idPost;
	    string idUser;
	    uint64 nbResults;
	    mapping (uint64 => bytes32) results;
	    bytes32 prevResult;
	}

	
	mapping (bytes32  => Campaign) public campaigns;
	mapping (bytes32  => promElement) public proms;
	mapping (bytes32  => Result) public results;
	mapping (address  => OracleUnit) public oraclelist;
	mapping (bytes32 => bool) public isAlreadyUsed;
	
	
	event CampaignCreated(bytes32 indexed id,uint64 startDate,uint64 endDate,string dataUrl);
	event CampaignFundsSpent(bytes32 indexed id );
	event CampaignApplied(bytes32 indexed id ,bytes32 indexed prom );
    event PromAccepted(bytes32 indexed id );
    event PromPayed(bytes32 indexed id ,uint256 amount);
    event CampaignFunded(bytes32 indexed id,uint256 amount);
	
    
    function createCampaign(string memory dataUrl,	uint64 startDate,uint64 endDate) public returns (bytes32 idCampaign) {
        require(startDate > block.timestamp,"start date too early");
        require(endDate > block.timestamp,"end date too early");
        require(endDate > startDate,"end date early than start");
       
        bytes32 campaignId = keccak256(abi.encodePacked(msg.sender,dataUrl,startDate,endDate,block.timestamp));
         // Campaign(msg.sender,dataUrl,startDate,endDate,0,0,0,Fund(address(0),0),0);
        Campaign storage c = campaigns[campaignId];
        c.advertiser = msg.sender;
        c.dataUrl = dataUrl;
        c.startDate = startDate;
        c.endDate = endDate;
        c.nbProms = 0;
        c.nbValidProms = 0;
        c.funds = Fund(address(0),0);
        emit CampaignCreated(campaignId,startDate,endDate,dataUrl);
        return campaignId;
    }
    
    
    
    function modCampaign(bytes32 idCampaign,string memory dataUrl,	uint64 startDate,uint64 endDate) public {
        require(campaigns[idCampaign].advertiser == msg.sender,"campaign owner mismatch");
        require(campaigns[idCampaign].startDate > block.timestamp,"campaign already started");
        require(startDate > block.timestamp,"start date too early");
        require(endDate > block.timestamp,"end date too early");
        require(endDate > startDate,"end date early than start");
       
        campaigns[idCampaign].dataUrl = dataUrl;
        campaigns[idCampaign].startDate = startDate;
        campaigns[idCampaign].endDate = endDate;
        emit CampaignCreated(idCampaign,startDate,endDate,dataUrl);
    }
    
     function priceRatioCampaign(bytes32 idCampaign,uint8 typeSN,uint256 likeRatio,uint256 shareRatio,uint256 viewRatio,uint256 limit) public {
        require(campaigns[idCampaign].advertiser == msg.sender,"campaign owner mismatch");
        require(campaigns[idCampaign].startDate > block.timestamp,"campaign already started");
        campaigns[idCampaign].ratios[typeSN] = cpRatio(likeRatio,shareRatio,viewRatio,limit);
    }
    
  
    
    function fundCampaign (bytes32 idCampaign,address token,uint256 amount) public {
        require(campaigns[idCampaign].endDate > block.timestamp,"campaign ended");
        require(campaigns[idCampaign].funds.token == address(0) || campaigns[idCampaign].funds.token == token,"token mismatch");
       
        IERC20 erc20 = IERC20(token);
        erc20.transferFrom(msg.sender,address(this),amount);
        uint256 prev_amount = campaigns[idCampaign].funds.amount;
        
        if(token == 0xDf49C9f599A0A9049D97CFF34D0C30E468987389 || token == 0x448BEE2d93Be708b54eE6353A7CC35C4933F1156) {
            campaigns[idCampaign].funds = Fund(token,amount+prev_amount);
            emit CampaignFunded(idCampaign,amount);
        }
        else {
            campaigns[idCampaign].funds = Fund(token,(amount*85/100)+prev_amount);
            emit CampaignFunded(idCampaign,(amount*85/100));
        }
      
    }
    
    function createPriceFundYt(string memory dataUrl,uint64 startDate,uint64 endDate,uint256 likeRatio,uint256 viewRatio,address token,uint256 amount,uint256 limit) public returns (bytes32 idCampaign) {
        bytes32 campaignId = createCampaign(dataUrl,startDate,endDate);
        priceRatioCampaign(campaignId,2,likeRatio,0,viewRatio,limit);
        fundCampaign(campaignId,token,amount);
        return campaignId;
    }
    
    function createPriceFundAll(
            string memory dataUrl,
            uint64  startDate,
            uint64 endDate,
            
             uint256[] memory ratios,
            address token,
            uint256 amount) public returns (bytes32 idCampaign) {
        
        
         require(startDate > block.timestamp,"start date too early");
        require(endDate > block.timestamp,"end date too early");
        require(endDate > startDate,"end date early than start");
       
        bytes32 campaignId = keccak256(abi.encodePacked(msg.sender,dataUrl,startDate,endDate,block.timestamp));
        Campaign storage c = campaigns[campaignId];
        c.advertiser = msg.sender;
        c.dataUrl = dataUrl;
        c.startDate = startDate;
        c.endDate = endDate;
        c.nbProms = 0;
        c.nbValidProms = 0;
        c.funds = Fund(address(0),0);
        //campaigns[campaignId] = Campaign(msg.sender,dataUrl,startDate,endDate,0,0,Fund(address(0),0));
        emit CampaignCreated(campaignId,startDate,endDate,dataUrl);
        
     

            for (uint8 i=0;i<ratios.length;i=i+4) {
              priceRatioCampaign(campaignId,(i/4)+1,ratios[i],ratios[i+1],ratios[i+2],ratios[i+3]);
            }
            
            
       
        fundCampaign(campaignId,token,amount);
        return campaignId;
    }
    
    function createPriceFundBounty(
            string memory dataUrl,
            uint64  startDate,
            uint64 endDate,
            
             uint256[] memory bounties,
            address token,
            uint256 amount) public returns (bytes32 idCampaign) {
        
        require(startDate > block.timestamp,"start date too early");
        require(endDate > block.timestamp,"end date too early");
        require(endDate > startDate,"end date early than start");
       
        bytes32 campaignId = keccak256(abi.encodePacked(msg.sender,dataUrl,startDate,endDate,block.timestamp));
        Campaign storage c = campaigns[campaignId];
        c.advertiser = msg.sender;
        c.dataUrl = dataUrl;
        c.startDate = startDate;
        c.endDate = endDate;
        c.nbProms = 0;
        c.nbValidProms = 0;
        c.funds = Fund(address(0),0);
        for (uint i=0;i<bounties.length;i=i+4) {
            c.bounties.push(bountyUnit(bounties[i],bounties[i+1],bounties[i+2],bounties[i+3]));
        }
        
        emit CampaignCreated(campaignId,startDate,endDate,dataUrl);
        
        
        fundCampaign(campaignId,token,amount);
        return campaignId;
    }
    
    function applyCampaign(bytes32 idCampaign,uint8 typeSN, string memory idPost, string memory idUser) public returns (bytes32 idProm) {
        bytes32 prom = keccak256(abi.encodePacked(idCampaign,typeSN,idPost,idUser));
        require(campaigns[idCampaign].endDate > block.timestamp,"campaign ended");
        require(!isAlreadyUsed[prom],"link already sent");
        bytes32 newIdProm = keccak256(abi.encodePacked( msg.sender,typeSN,idPost,idUser,block.timestamp));
        promElement storage p = proms[newIdProm];
        p.influencer = msg.sender;
        p.idCampaign = idCampaign;
        p.isAccepted = false;
        p.funds = Fund(address(0),0);
        p.typeSN = typeSN;
        p.idPost = idPost;
        p.idUser = idUser;
        p.nbResults = 0;
        p.prevResult = 0;
        //proms[idProm] = promElement(msg.sender,idCampaign,false,Fund(address(0),0),typeSN,idPost,idUser,0,0);
        campaigns[idCampaign].proms[campaigns[idCampaign].nbProms++] = newIdProm;
        
        bytes32 idRequest = keccak256(abi.encodePacked(typeSN,idPost,idUser,block.timestamp));
        results[idRequest] = Result(newIdProm,0,0,0);
        proms[newIdProm].results[0] = proms[newIdProm].prevResult = idRequest;
        proms[newIdProm].nbResults = 1;
        
        //ask(typeSN,idPost,idUser,idRequest);
        
        isAlreadyUsed[prom] = true;
        
        emit CampaignApplied(idCampaign,newIdProm);
        return newIdProm;
    }
    
    function validateProm(bytes32 idProm) public {
        Campaign storage cmp = campaigns[proms[idProm].idCampaign];
        require(cmp.endDate > block.timestamp,"campaign ended");
        require(cmp.advertiser == msg.sender,"campaign owner mismatch");
        
        proms[idProm].isAccepted = true;
        cmp.nbValidProms++;

        emit PromAccepted(idProm);
    }

    function validateProms(bytes32[] memory idProms) public {
        for(uint64 i = 0;i < idProms.length ;i++) {
            validateProm(idProms[i]);
        }
    }
    
    
    function startCampaign(bytes32 idCampaign) public  {
         require(campaigns[idCampaign].advertiser == msg.sender || msg.sender == owner,"campaign owner mismatch" );
         require(campaigns[idCampaign].startDate > block.timestamp,"campaign already started");
         campaigns[idCampaign].startDate = uint64(block.timestamp);
    }
    
    function updateCampaignStats(bytes32 idCampaign) public  {
        for(uint64 i = 0;i < campaigns[idCampaign].nbProms ;i++)
        {
            bytes32 idProm = campaigns[idCampaign].proms[i];
            if(proms[idProm].isAccepted) {
                bytes32 idRequest = keccak256(abi.encodePacked(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,block.timestamp));
                results[idRequest] = Result(idProm,0,0,0);
                proms[idProm].results[proms[idProm].nbResults++] = idRequest;
                ask(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,idRequest);
            }
        }
    }
    
    function updatePromStats(bytes32 idProm) public returns (bytes32 requestId) {
        require(proms[idProm].isAccepted,"link not validated"); 
        bytes32 idRequest = keccak256(abi.encodePacked(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,block.timestamp));
        results[idRequest] = Result(idProm,0,0,0);
        proms[idProm].results[proms[idProm].nbResults++] = idRequest;
        ask(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,idRequest);
        return idRequest;
    }
    
    function updateBounty(bytes32 idProm) public  {
        require(proms[idProm].isAccepted,"link not validated");
        askBounty(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,idProm);
    }
    
    function endCampaign(bytes32 idCampaign) public  {
        require(campaigns[idCampaign].endDate > block.timestamp,"campaign already ended");
        require(campaigns[idCampaign].advertiser == msg.sender || msg.sender == owner,"campaign owner mismatch" );
        campaigns[idCampaign].endDate = uint64(block.timestamp);
    }
    
    
    function ask(uint8 typeSN, string memory idPost,string memory idUser,bytes32 idRequest) public {
        IOracle o = IOracle(oracle);
        o.ask(typeSN,idPost,idUser,idRequest);
    }
    
    function askBounty(uint8 typeSN, string memory idPost,string memory idUser,bytes32 idProm) public {
        IOracle o = IOracle(oracle);
        o.askBounty(typeSN,idPost,idUser,idProm);
    }
    
    function updateBounty(bytes32 idProm,uint256 nbAbos) external  returns (bool ok) {
        require(msg.sender == oracle,"oracle mismatch");
        
        promElement storage prom = proms[idProm];
        require(!prom.isPayed,"link already paid");
        prom.isPayed= true;
        prom.funds.token = campaigns[prom.idCampaign].funds.token;
        
        uint256 gain = 0;
        for(uint256 i = 0;i<campaigns[prom.idCampaign].bounties.length;i++){
            if(nbAbos >= campaigns[prom.idCampaign].bounties[i].minRange &&  nbAbos < campaigns[prom.idCampaign].bounties[i].maxRange && prom.typeSN == campaigns[prom.idCampaign].bounties[i].typeSN)
            {
                gain = campaigns[prom.idCampaign].bounties[i].amount;
            }
        }
        
        if(campaigns[prom.idCampaign].funds.amount <= gain )
        {
            campaigns[prom.idCampaign].endDate = uint64(block.timestamp);
            prom.funds.amount += campaigns[prom.idCampaign].funds.amount;
            campaigns[prom.idCampaign].funds.amount = 0;
            emit CampaignFundsSpent(prom.idCampaign);
            return true;
        }
        campaigns[prom.idCampaign].funds.amount -= gain;
        prom.funds.amount += gain;
        return true;
        
    }
    
    function update(bytes32 idRequest,uint64 likes,uint64 shares,uint64 views) external  returns (bool ok) {
        require(msg.sender == oracle,"oracle mismatch");
        
        IOracle o = IOracle(oracle);
        uint256 f = o.oracleFee(tx.origin);
        promElement storage prom = proms[results[idRequest].idProm];
        
        if(f<0)
        {
           
            if(oraclelist[address(msg.sender)].funds.token == address(0))
            {
                oraclelist[msg.sender].funds.token = campaigns[prom.idCampaign].funds.token;
            }
            require(oraclelist[address(msg.sender)].funds.token == campaigns[prom.idCampaign].funds.token,"oracle funds mismatch");
            oraclelist[msg.sender].funds.amount += f;
            campaigns[prom.idCampaign].funds.amount -= f;
        }
       
        results[idRequest].likes = likes;
        results[idRequest].shares = shares;
        results[idRequest].views = views;
       
        uint256 gain = 0;
        
        if(likes > results[prom.prevResult].likes)
            gain += (likes - results[prom.prevResult].likes)* campaigns[prom.idCampaign].ratios[prom.typeSN].likeRatio;
        if(shares > results[prom.prevResult].shares)
            gain += (shares - results[prom.prevResult].shares)* campaigns[prom.idCampaign].ratios[prom.typeSN].shareRatio;
         if(views > results[prom.prevResult].views)
        gain += (views - results[prom.prevResult].views)* campaigns[prom.idCampaign].ratios[prom.typeSN].viewRatio;
        prom.prevResult = idRequest;
        
        //
        // warn campaign low credits
        //
       
       
        if(prom.funds.token == address(0))
        {
            prom.funds.token = campaigns[prom.idCampaign].funds.token;
        }
        if(campaigns[prom.idCampaign].funds.amount <= gain )
        {
            campaigns[prom.idCampaign].endDate = uint64(block.timestamp);
            prom.funds.amount += campaigns[prom.idCampaign].funds.amount;
            campaigns[prom.idCampaign].funds.amount = 0;
            emit CampaignFundsSpent(prom.idCampaign);
            return true;
        }
        campaigns[prom.idCampaign].funds.amount -= gain;
        prom.funds.amount += gain;
        return true;
    }
    
    function getGains(bytes32 idProm) public {
        require(proms[idProm].influencer == msg.sender,"link owner mismatch");
        IERC20 erc20 = IERC20(proms[idProm].funds.token);
        uint256 amount = proms[idProm].funds.amount;
        proms[idProm].funds.amount = 0;
        erc20.transfer(proms[idProm].influencer,amount);

        emit PromPayed(idProm,amount);
        
    }
    
    function getOracleFee() public {
        
        IERC20 erc20 = IERC20(oraclelist[msg.sender].funds.token);
        uint256 amount = oraclelist[msg.sender].funds.amount;
        oraclelist[msg.sender].funds.amount = 0;
        erc20.transfer(msg.sender,amount);
    }
    
    function getRemainingFunds(bytes32 idCampaign) public {
        require(campaigns[idCampaign].advertiser == msg.sender,"campaign owner mismatch");
        require(campaigns[idCampaign].endDate < block.timestamp,"campaign not ended");
        IERC20 erc20 = IERC20(campaigns[idCampaign].funds.token);
        uint256 amount = campaigns[idCampaign].funds.amount;
        campaigns[idCampaign].funds.amount = 0;
        erc20.transfer(campaigns[idCampaign].advertiser,amount);
    }
    
    function getProms (bytes32 idCampaign) public view returns (bytes32[] memory cproms)
    {
        uint nbProms = campaigns[idCampaign].nbProms;
        cproms = new bytes32[](nbProms);
        
        for (uint64 i = 0;i<nbProms;i++)
        {
            cproms[i] = campaigns[idCampaign].proms[i];
        }
        return cproms;
    }
    
    function getRatios (bytes32 idCampaign) public view returns (uint8[] memory types,uint256[] memory likeRatios,uint256[] memory shareRatios,uint256[] memory viewRatios,uint256[] memory limits )
    {   
        uint8 l = 10;
        types = new uint8[](l);
        likeRatios = new uint256[](l);
        shareRatios = new uint256[](l);
        viewRatios = new uint256[](l);
         limits = new uint256[](l);
        for (uint8 i = 0;i<l;i++)
        {
            types[i] = i+1;
            likeRatios[i] = campaigns[idCampaign].ratios[i+1].likeRatio;
            shareRatios[i] = campaigns[idCampaign].ratios[i+1].shareRatio;
            viewRatios[i] = campaigns[idCampaign].ratios[i+1].viewRatio;
            limits[i] = campaigns[idCampaign].ratios[i+1].reachLimit;
        }
        return (types,likeRatios,shareRatios,viewRatios,limits);
    }
    
    function getBounties (bytes32 idCampaign) public view returns (uint256[] memory bounty )
    { 
        bounty = new uint256[](campaigns[idCampaign].bounties.length*4);
        for (uint8 i = 0; i<campaigns[idCampaign].bounties.length; i++)
        {
         bounty[i*4] = campaigns[idCampaign].bounties[i].minRange;
         bounty[i*4+1] = campaigns[idCampaign].bounties[i].maxRange;
         bounty[i*4+2] = campaigns[idCampaign].bounties[i].typeSN;
         bounty[i*4+3] = campaigns[idCampaign].bounties[i].amount;
        }
        return bounty;
    }
    
    
    function getResults (bytes32 idProm) public view returns (bytes32[] memory creq)
    {
        uint nbResults = proms[idProm].nbResults;
        creq = new bytes32[](nbResults);
        for (uint64 i = 0;i<nbResults;i++)
        {
            creq[i] = proms[idProm].results[i];
        }
        return creq;
    }
    
    function getIsUsed(bytes32 idCampaign,uint8 typeSN, string memory idPost, string memory idUser) public view returns (bool) {
        bytes32 prom = keccak256(abi.encodePacked(idCampaign,typeSN,idPost,idUser));
        return isAlreadyUsed[prom];
    }
    
    
}