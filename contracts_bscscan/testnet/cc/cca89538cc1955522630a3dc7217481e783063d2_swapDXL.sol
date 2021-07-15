//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import './Ownable.sol';
import './Context.sol';
import './SafeMath.sol';
import './IBEP20.sol';

contract swapDXL is Ownable {
    using SafeMath for uint;
    
    event swap( address indexed _buyer, uint _valueDEEDEE, uint _valueDXL);
    
    uint256 public DEEDEEPrice = 10e18; // 10 DXL == 1 DEEDEE;
    uint256 public DXLLimit = 200e18;
    uint256 public amountDXL = 0; //amount of deposited DXL
    
    uint public _minimumIvestment = 0.01e18; // 0 DXL.
    
    IBEP20 public DEEDEE = IBEP20(0xB9994c32f811A02F1A9582ef1f9CFD95FFDb5772);
    IBEP20 public DXL = IBEP20(0x63eF638Be1009c78B36582AacBB2b13d0E362B94);
       
    uint256 public totalSoldDXL = 0;
    uint256 public totalSoldDEEDEE = 0;
     
    function swapDXLForDEEDEEToken(uint256 _amount) external {
    	amountDXL = _amount;

        require(!isContract(_msgSender()),"swapDXLForDEEDEEToken :: Caller must not be contract address");
        require(amountDXL >= _minimumIvestment, "swapDXLForDEEDEEToken :: wallet should deposit > 0 DXL at a time");
        require(amountDXL <= DXLLimit, "swapDXLForDEEDEEToken :: wallet can buy max 200 DXL");
    	require(DEEDEE.balanceOf(address(this)) >= amountDXL,"insufficient DEEDEE amount on the contract");

        uint amountDeeDee = amountDXL.div(DEEDEEPrice); 

    	//approve spending DXL
    	require(DXL.approve(msg.sender, amountDXL),"swapDXLForDEEDEEToken :: DXL spending approval failed");    

    	//transfer DEEDEE to sender
      	require(DEEDEE.transfer(msg.sender, amountDeeDee),"swapDXLForDEEDEEToken :: DEEDEE transfer failed");        
    
    	DXL.transfer(address(this),amountDXL); //transfer DXL to contract
        
        totalSoldDXL = totalSoldDXL.add(amountDXL);
        totalSoldDEEDEE= totalSoldDEEDEE.add(amountDeeDee);
        
        emit swap( _msgSender(), amountDeeDee, amountDXL);
    }



    
    function updatePrce( uint _DEEDEEPrice) external onlyOwner {
        DEEDEEPrice = _DEEDEEPrice;
    }
    
    function updateDXLLimit( uint _DXLLimit) external onlyOwner {
        DXLLimit = _DXLLimit;
    }
    
    function updateMinimumInvestment( uint minimumInvestment) public onlyOwner {
        _minimumIvestment = minimumInvestment;
    }
    
    function getPrice(uint amountIn) public view returns (uint) {
        return DEEDEEPrice.mul(amountIn).div(1e18);
    }
    
    function failSafe( uint _amount) public onlyOwner {
        require(DEEDEE.balanceOf(address(this)) >= _amount, "failSafe :: insufficient amount");
        DEEDEE.transfer(_msgSender(),_amount);
    }
    
    function failSafeBNB( uint _amount) public onlyOwner {
        address _contract = address(this);
        require(_contract.balance >= _amount,"insufficient amount");
        msg.sender.transfer(_amount);
    }
 
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }   
}