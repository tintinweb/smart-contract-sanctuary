//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import './Ownable.sol';
import './Context.sol';
import './SafeMath.sol';
import './IBEP20.sol';

contract swapCALCIFER is Ownable {
    using SafeMath for uint;

    event swap(address indexed _buyer, uint256 _valueCALCIFIRE, uint256 _valueCALCIFER);

    uint256 public swapRate = 1; // 1 CALCIFER == 1 CALCIFIRE;
    uint256 public CALCIFERLimit = 500000e18;
    uint256 public amountCALCIFER = 0; //amount of deposited CALCIFER
    uint256 amountCALCIFIRE = 0; //resulting CALCIFIRE to transfer

    uint256 public _minimumIvestment = 0.0001e18; // 0 CALCIFER.

    IBEP20 public CALCIFIRE = IBEP20(0x36a7a0c60cb77297c7006A6fb2b07748ad7BdaB8);
    IBEP20 public CALCIFER = IBEP20(0xE6ce3540e7b7B113c0F6b490136148a61d5EfdfC);

    uint256 public totalSwappedCALCIFER = 0;
    uint256 public totalSwappedCALCIFIRE = 0;

    function swapCALCIFERToCALCIFIREToken(uint256 _amount) external {
    	  amountCALCIFER = _amount;

        require(!isContract(_msgSender()),"swapCALCIFERToCALCIFIREToken :: Caller must not be contract address");
        require(amountCALCIFER >= _minimumIvestment, "swapCALCIFERToCALCIFIREToken :: wallet should deposit > 0 CALCIFER at a time");
        require(amountCALCIFER <= CALCIFERLimit, "swapCALCIFERToCALCIFIREToken :: wallet can transfer max 500000 CALCIFER");
    	  require(CALCIFIRE.balanceOf(address(this)) >= amountCALCIFER.div(swapRate),"insufficient CALCIFIRE amount on the contract");

        amountCALCIFIRE = amountCALCIFER.div(swapRate);

        //contract should be allowed to spend CALCIFER
      	require(CALCIFER.allowance(msg.sender,address(this)) >= amountCALCIFER,"swapCALCIFERToCALCIFIREToken :: not allowed to spend CALCIFER");

    	  //transfer CALCIFIRE to sender
      	require(CALCIFIRE.transfer(msg.sender, amountCALCIFIRE),"swapCALCIFERToCALCIFIREToken :: CALCIFIRE transfer failed");

        //transfer CALCIFER to dev addr
    	  require(CALCIFER.transferFrom(msg.sender,address(0x23A29F6700282e127dE4f42e8624484870D7817F),amountCALCIFER),"swapCALCIFERToCALCIFIREToken :: CALCIFER transfer failed");

        totalSwappedCALCIFER = totalSwappedCALCIFER.add(amountCALCIFER);
        totalSwappedCALCIFIRE= totalSwappedCALCIFIRE.add(amountCALCIFIRE);

        emit swap( _msgSender(), amountCALCIFIRE, amountCALCIFER);
    }


    function failSafeCALCIFIRE( uint256 _amount) public onlyOwner {
        require(CALCIFIRE.balanceOf(address(this)) >= _amount, "failSafeCALCIFIRE :: insufficient amount");
        CALCIFIRE.transfer(_msgSender(),_amount);
    }

    function failSafeCALCIFER( uint256 _amount) public onlyOwner {
        require(CALCIFER.balanceOf(address(this)) >= _amount, "failSafeCALCIFER :: insufficient amount");
        CALCIFER.transfer(_msgSender(),_amount);
    }

    function updateRate( uint256 _swapRate) external onlyOwner {
        swapRate = _swapRate;
    }

    function updateCALCIFERLimit( uint256 _CALCIFERLimit) external onlyOwner {
        CALCIFERLimit = _CALCIFERLimit;
    }

    function updateMinimumInvestment( uint256 minimumInvestment) public onlyOwner {
        _minimumIvestment = minimumInvestment;
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