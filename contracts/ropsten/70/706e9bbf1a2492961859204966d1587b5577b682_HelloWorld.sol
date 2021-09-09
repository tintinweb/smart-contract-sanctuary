/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;



contract HelloWorld{
    
    function hello() public view returns(string memory){
        return "我是中文";
    }
    
    
	function getOffer() public view returns(Offer memory) {
	    NFTMeta memory nftMeta = NFTMeta({
	        name:'sdkjlf',
	        intro:'salkdjjlkadslkjfdslkj',
	        des:'aaaabbbb'
	    });
		Offer memory offer = Offer({
		    id:1,
			borrower: msg.sender,
			loanToken: msg.sender,
			loanAmount: 1,
			loanRepayment: 1,
			loanDuration: 1,
			publishTime: now,
			nftToken: msg.sender,
			nftId: 11,
			status: 0,
			lender: address(0),
			meta: nftMeta
		});
		return offer;
	}
	
	struct Offer {
		uint256 id;
		address borrower;
		address loanToken;
		uint256 loanAmount;
		uint256 loanRepayment;
		uint256 loanDuration;
		uint256 publishTime;
		address nftToken;
		uint256 nftId;
		uint256 status; 
		address lender;
		NFTMeta meta;
	}
	
	
	struct NFTMeta {
		string name;
		string intro;
		string des;
	}

}