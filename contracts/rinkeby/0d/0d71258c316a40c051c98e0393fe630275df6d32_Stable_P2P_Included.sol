/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Stable_P2P_Included {
    address ownerAddress;
    address payable buyer;
    address payable buyerStable;    
    address payable seller;

    IERC20 public token1;
    address public owner1;
    uint public amount1;


    constructor(){
	    ownerAddress = msg.sender ;
    }
   
    uint256 jumlah;
    uint256 _saldoToken;

    address alamat;
    address payable juragan = payable(0x4c21d91b5fe56e5829f7A3930f4042309cd056E5);
    bool public _claim = false;
    bool public _claimstable = false;
    bool public _approve = false;
    bool public _approvestable = false;
    bool public _depo = false;
    bool public _depostable = false;
    

    function tokenTransfer(
        IERC20 token,
        address sender,
        address recipient,
        uint amount
    ) public {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

	function transferToAddressETH(address payable recipient, uint256 amount) public {
        recipient.transfer(amount);
    }

	function Deposit(uint256 _amount) external payable  {
	    require(msg.sender == ownerAddress, "Only Owner");
	   
        jumlah = _amount;
        _depo = true;
        seller = (payable (msg.sender));
        //(bool success, ) = ownerAddress.call{value: amount}("");
        //transferToAddressETH(address(this), jumlah);
	}

	/***function amountSell(uint256 _amount) external payable {
	require(msg.sender == ownerAddress, "Only Owner");
    require(msg.value > 1e17, "Minimum 0.1 USDT IS REQUIRED");	
    jumlah = _amount;
	}*/


	function DepositStable(IERC20 token, uint amount) external payable  {
	    
        _depostable = true;
        seller = (payable (msg.sender));
        tokenTransfer(token, msg.sender, address(this), amount);
	}

    function withdrawStable(IERC20 token) public {
        require(msg.sender == seller, "Only Owner");
        _saldoToken = IERC20(token).balanceOf(address(this));

         _depostable = false;
         _claimstable = false;
         buyerStable = seller;
         
        tokenTransfer(token, address(this), msg.sender, _saldoToken);

    }

    // baru sampai Sini 
    function withdraw() public {
        require(msg.sender == seller, "Only Owner");

        uint amount = address(this).balance;

        (bool success, ) = ownerAddress.call{value: amount}("");
        require(success, "Failed to send Ether");
        _depo = false;
        _claim = false;
        buyer = seller;
    }

    function approveStable(IERC20 token) public {
    	    seller = (payable (msg.sender));
            _approvestable = true;
            
            _saldoToken = IERC20(token).balanceOf(address(this));
            
            uint fintransfer = _saldoToken*997/1000;
            uint pajak = _saldoToken*3/1000;

    
    		if (_claimstable && _approvestable) {
		        tokenTransfer(token, seller, buyerStable, fintransfer);	
		        tokenTransfer(token, seller, juragan, pajak);	

    			_claimstable = false;
    			_depostable = false;
    			buyerStable = seller;
    				
    			}
        }

	function approve() public {
	    seller = (payable (msg.sender));
        _approve = true;
        
        uint amount = address(this).balance;
        
        uint fintransfer = amount*997/1000;
        uint pajak = amount*3/1000;

		if (_claim && _approve) {
				
			transferToAddressETH(buyer, fintransfer);
			transferToAddressETH(juragan, pajak);
			
			_depo = false;
			_claim = false;
			buyer = seller;
				
			}
    } 

	function claim() public {
	    
	    require(_depo == false, "fund has not been deposited yet");
	    
	    buyer = (payable (msg.sender));
	    
        _claim = true;
    } 


	function claimstable() public {
	    
	    require(_depo == false, "fund has not been deposited yet");
	    
	    buyerStable = (payable (msg.sender));
	    
        _claimstable = true;
    } 


    function showAcc() public view returns (bool) {
        return _approve;
    }

    function showAccStable() public view returns (bool) {
        return _approvestable;
    }

    function DepoStatus() public view returns (bool) {
        return _depo;
    }

    function DepoStatusStable() public view returns (bool) {
        return _depostable;
    }

    function showClaim() public view returns (bool) {
        return _claim;
    }

    function showClaimStable() public view returns (bool) {
        return _claimstable;
    }
    
    function showBuyer() public view returns (address) {
        return buyer;
    }

    function showBuyerStable() public view returns (address) {
        return buyerStable;
    }
    
    function showSeller() public view returns (address) {
        return seller;
    }
}