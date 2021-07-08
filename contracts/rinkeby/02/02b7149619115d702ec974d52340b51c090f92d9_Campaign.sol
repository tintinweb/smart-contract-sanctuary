/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.4.21;

/**
 *  Author   : Anisa Sholichawati
 	Date	 : 30 November 2020
 	Properti : bytes32 title, uint goal, bytes32 endDate, int pledged, bytes32 desc, bytes pict, uint note, uint index, uint recipientIndex, uint recipientToCampaignIndex
 	Argumen	 : bytes32 _title, uint _goal, bytes32 _endDate, int _pledged, bytes32 _desc, bytes _pict, uint _note, uint _index, uint _recipientIndex, uint _recipientToCampaignIndex
 */
 contract Campaign {
 	struct detailStruct{
 		bytes32 title;
 		uint goal;
 		bytes32 endDate;
 		int pledged;
 		bytes32 desc;
 		bytes pict;
 		uint note; // 0 = mati DL, 1 = mati goal, 2 = mati user, 3 = aktif
 		uint index;
 		uint recipientIndex;
 		uint recipientToCampaignIndex;	
 	}
 	bytes32[] private campaign;
 	address[] private recipient;

 	mapping (bytes32 => detailStruct) private campaignToDetail;
 	mapping (address => bytes32[]) private recipientToCampaign;

 	event NewCampaign(bytes32 indexed campaign, uint index, bytes32 title, uint goal, bytes32 endDate, uint note, address recipientAddress);
 	event UpdateCampaign(bytes32 indexed campaign, uint index, bytes32 title, uint goal, bytes32 endDate, uint note, address recipientAddress); 	


 	function isRecipient(address _sellerAddress) public view returns(bool isIndeed){
 		if(recipient.length == 0) return false;
 		return(recipientToCampaign[_sellerAddress].length > 0);
 	}
 	
 	function isCampaign( bytes32 _campaign) public view returns(bool isIndeed){
 		if(campaign.length == 0) return false;

 		return(campaign[campaignToDetail[_campaign].index] == _campaign);
 	}
 	

 	function insertCampaign(address _recipientAddress, bytes32 _campaign, bytes32 _title, uint _goal, bytes32 _endDate, int _pledged, bytes32 _desc, bytes _pict) public returns(bool success){
 		require (!isCampaign(_campaign));
 		
 		if(!isRecipient(_recipientAddress)){
 			campaignToDetail[_campaign].recipientIndex = recipient.push(_recipientAddress)-1;
 		}
 		else {
 			campaignToDetail[_campaign].recipientIndex = campaignToDetail[recipientToCampaign[_recipientAddress][0]].recipientIndex;
 		}
 		
 		campaignToDetail[_campaign].title = _title;
 		campaignToDetail[_campaign].goal = _goal;
 		campaignToDetail[_campaign].endDate = _endDate;
 		campaignToDetail[_campaign].pledged = _pledged;
 		campaignToDetail[_campaign].desc = _desc;
 		campaignToDetail[_campaign].pict = _pict;
 		campaignToDetail[_campaign].note = 0;
 		campaignToDetail[_campaign].index = campaign.push(_campaign)-1;
 		campaignToDetail[_campaign].recipientToCampaignIndex = recipientToCampaign[_recipientAddress].push(_campaign)-1;

 		emit NewCampaign(_campaign, campaignToDetail[_campaign].index, _title, _goal, _endDate, 0, _recipientAddress);
 		return true;
 	}
 	
 	function updateTitle(address _recipientAddress, bytes32 _campaign, bytes32 _title) public returns(bool success){
 		require (isCampaign(_campaign));
 		require (isRecipient(_recipientAddress));
 		
 		campaignToDetail[_campaign].title = _title;

 		emit UpdateCampaign(_campaign, campaignToDetail[_campaign].index, _title, campaignToDetail[_campaign].goal, campaignToDetail[_campaign].endDate, campaignToDetail[_campaign].note, _recipientAddress);
 		return true;
 	}

 	function updateGoal(address _recipientAddress, bytes32 _campaign, uint _goal) public returns(bool success){
 		require (isCampaign(_campaign));
 		require (isRecipient(_recipientAddress));
 		
 		campaignToDetail[_campaign].goal = _goal;
 		
 		emit UpdateCampaign(_campaign, campaignToDetail[_campaign].index, campaignToDetail[_campaign].title, _goal, campaignToDetail[_campaign].endDate, campaignToDetail[_campaign].note, _recipientAddress);
 		return true;
 	}
 	
 	function updateEndDate(address _recipientAddress, bytes32 _campaign, bytes32 _endDate) public returns(bool success){
 		require (isCampaign(_campaign));
 		require (isRecipient(_recipientAddress));
 		
 		campaignToDetail[_campaign].endDate = _endDate;

 		emit UpdateCampaign(_campaign, campaignToDetail[_campaign].index, campaignToDetail[_campaign].title, campaignToDetail[_campaign].goal, _endDate, campaignToDetail[_campaign].note, _recipientAddress);
 		return true;
 	}
 	
 	function updatePledged(address _recipientAddress, bytes32 _campaign, int _pledged) public returns(bool success){
 		require (isCampaign(_campaign));
 		require (isRecipient(_recipientAddress));
 		
 		campaignToDetail[_campaign].pledged += _pledged;

 		emit UpdateCampaign(_campaign, campaignToDetail[_campaign].index, campaignToDetail[_campaign].title, campaignToDetail[_campaign].goal, campaignToDetail[_campaign].endDate, campaignToDetail[_campaign].note, _recipientAddress);
 		return true;
 	}

 	function updateDesc(address _recipientAddress, bytes32 _campaign, bytes32 _desc) public returns(bool success){
 		require (isCampaign(_campaign));
 		require (isRecipient(_recipientAddress));
 		
 		campaignToDetail[_campaign].desc = _desc;

 		emit UpdateCampaign(_campaign, campaignToDetail[_campaign].index, campaignToDetail[_campaign].title, campaignToDetail[_campaign].goal, campaignToDetail[_campaign].endDate, campaignToDetail[_campaign].note, _recipientAddress);
 		return true;
 	}

 	function updatePict(address _recipientAddress, bytes32 _campaign, bytes _pict) public returns(bool success){
 		require (isCampaign(_campaign));
 		require (isRecipient(_recipientAddress));
 		
 		campaignToDetail[_campaign].pict = _pict;

 		emit UpdateCampaign(_campaign, campaignToDetail[_campaign].index, campaignToDetail[_campaign].title, campaignToDetail[_campaign].goal, campaignToDetail[_campaign].endDate, campaignToDetail[_campaign].note, _recipientAddress);
 		return true;
 	}

 	function updateNote(address _recipientAddress, bytes32 _campaign, uint _note) public returns(bool success){
 		require (isCampaign(_campaign));
 		require (isRecipient(_recipientAddress));
 		
 		
 		campaignToDetail[_campaign].note = _note;

 		emit UpdateCampaign(_campaign, campaignToDetail[_campaign].index, campaignToDetail[_campaign].title, campaignToDetail[_campaign].goal, campaignToDetail[_campaign].endDate,  _note, _recipientAddress);
 		return true;
 	}

 	function stoppedByUser(address _recipientAddress, bytes32 _campaign) public returns(bool success){
      require(getNoteByIndex(getIndexByCampaign(_campaign)) == 3);

      updateNote(_recipientAddress, _campaign, 2);
    }

 	function getCampaignCount() public view returns(uint _count){
 		return campaign.length;
 	}

 	function getCampaignCountByAddress(address _recipientAddress) public view returns(uint count){
 		return recipientToCampaign[_recipientAddress].length;
 	}

 	function getRecipientCount() public view returns(uint count){
 		return recipient.length;
 	}
 	
 	function getCampaignByIndex(uint _index) public view returns(bytes32 campaignCode){
 		return campaign[_index];
 	}

 	function getCampaignByRecipientToCampaignIndex(address _recipientAddress, uint _index) public view returns(bytes32 campaignCode){
 		return recipientToCampaign[_recipientAddress][_index];
 	}

 	function getRecipientByRecipientIndex(uint _index) public view returns(address recipientAddress){
 		return recipient[campaignToDetail[campaign[_index]].recipientIndex];
 	}
 	
 	function getRecipientByIndex(uint _index) public view returns(address sellerAddress){
 		return recipient[_index];
 	}
 	
 	function getTitleByIndex(uint _index) public view returns(bytes32 title){
 		return campaignToDetail[campaign[_index]].title;
 	}
 	
 	function getTitleByRecipientToCampaignIndex(address _recipientAddress, uint _index) public view returns(bytes32 title){
 		return campaignToDetail[recipientToCampaign[_recipientAddress][_index]].title;
 	}
 	
 	function getGoalByIndex(uint _index) public view returns(uint goal){
 		return campaignToDetail[campaign[_index]].goal;
 	}
 	
 	function getGoalByRecipientToCampaignIndex(address _recipientAddress, uint _index) public view returns(uint goal){
 		return campaignToDetail[recipientToCampaign[_recipientAddress][_index]].goal;
 	}
 	
 	function getEndDateByIndex(uint _index) public view returns(bytes32 endDate){
 		return campaignToDetail[campaign[_index]].endDate;
 	}
 	
 	function getEndDateByRecipientToCampaignIndex(address _recipientAddress, uint _index) public view returns(bytes32 endDate){
 		return campaignToDetail[recipientToCampaign[_recipientAddress][_index]].endDate;
 	}

 	function getPledgedByIndex(uint _index) public view returns(int pledged){
 		return campaignToDetail[campaign[_index]].pledged;
 	}
 	
 	function getPledgedByRecipientToCampaignIndex(address _recipientAddress, uint _index) public view returns(int pledged){
 		return campaignToDetail[recipientToCampaign[_recipientAddress][_index]].pledged;
 	}
 	
 	function getDescByIndex(uint _index) public view returns(bytes32 desc){
 		return campaignToDetail[campaign[_index]].desc;
 	}
 	
 	function getDescByRecipientToCampaignIndex(address _recipientAddress, uint _index) public view returns(bytes32 desc){
 		return campaignToDetail[recipientToCampaign[_recipientAddress][_index]].desc;
 	}

 	function getPictByIndex(uint _index) public view returns(bytes pict){
 		return campaignToDetail[campaign[_index]].pict;
 	}
 	
 	function getPictByRecipientToCampaignIndex(address _recipientAddress, uint _index) public view returns(bytes pict){
 		return campaignToDetail[recipientToCampaign[_recipientAddress][_index]].pict;
 	}

 	function getNoteByIndex(uint _index) public view returns(uint note){
 		return campaignToDetail[campaign[_index]].note;
 	}
 	
 	function getNoteByRecipientToCampaignIndex(address _recipientAddress, uint _index) public view returns(uint note){
 		return campaignToDetail[recipientToCampaign[_recipientAddress][_index]].note;
 	}

 	function getIndexByCampaign(bytes32 _campaign) public view returns(uint index){
 		return campaignToDetail[_campaign].index;
 	}

 	function getRecipientIndexByAddress(address _recipientAddress, bytes32 _campaign) public view returns(uint index){
 		return campaignToDetail[recipientToCampaign[_recipientAddress][campaignToDetail[_campaign].recipientToCampaignIndex]].recipientIndex;
 	}
 	
 }