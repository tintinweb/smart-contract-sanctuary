//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import 'Ownable.sol';
import 'SafeMath.sol';
import 'IBEP20.sol';

contract Auction is Ownable {
    using SafeMath for uint256;

    uint8[3] private lotsCount;
    
    enum TYPES{ HIGH, MIDDLE, LOW }
    
    IBEP20 private _token;
    
    address[] private highAuction;
    address[] private middleAuction;
    address[] private lowAuction;
    
    event CreateAuction(uint8[]);
    event MakeBid(address, TYPES);
    event CloseAuction(address[], address[], address[]);
    
    constructor(IBEP20 token) {
        _token = token;
    }
    
    function createAuction(uint8[3] memory _lotsCount) public onlyOwner {
        lotsCount = _lotsCount;
    }
    
    function getAuctions(TYPES _type) public view returns(address[] memory _auction) {
        if(_type == TYPES.HIGH) {
            return highAuction;
        } else if(_type == TYPES.MIDDLE) {
            return middleAuction;
        } else if(_type == TYPES.LOW) {
            return lowAuction;
        }
    }
    
    function makeBid(TYPES _type) public {
        for(uint16 i=0; i<highAuction.length; ++i) {
            require(highAuction[i] != _msgSender(), 'You are already participating in this auction');
        }
      
        for(uint16 i=0; i<middleAuction.length; ++i) {
            require(middleAuction[i] != _msgSender(), 'You are already participating in this auction');
        }
        
        for(uint16 i=0; i<lowAuction.length; ++i) {
            require(lowAuction[i] != _msgSender(), 'You are already participating in this auction');
        }
        
        if(_type == TYPES.HIGH) {
            
            require(highAuction.length <= lotsCount[0], "Lot was bought");
            _token.transferFrom(_msgSender(), address(this), float(100));
            highAuction.push(_msgSender());
            
        } else if(_type == TYPES.MIDDLE) {

            require(middleAuction.length <= lotsCount[1], "Lot was bought");
            _token.transferFrom(_msgSender(), address(this), float(10));
            middleAuction.push(_msgSender());
                        
        } else if(_type == TYPES.LOW) {
            
            require(lowAuction.length <= lotsCount[2], "Lot was bought");
            _token.transferFrom(_msgSender(), address(this), float(1));
            lowAuction.push(_msgSender());
            
        } else {
            require(false, "Wrong type");
        }
        
        emit MakeBid(_msgSender(), _type);
    }
    
    function closeAction() public onlyOwner {
        for(uint8 h=0; h<highAuction.length; h++) {
            _token.transfer(highAuction[h], float(105));
        }
        
        for(uint8 h=0; h<middleAuction.length; h++) {
            _token.transfer(middleAuction[h], float(13));
        }
        
        for(uint8 h=0; h<lowAuction.length; h++) {
            _token.transfer(lowAuction[h], float(11, 1));
        }
        
        emit CloseAuction(highAuction, middleAuction, lowAuction);
        
        delete highAuction;
        delete middleAuction;
        delete lowAuction;
    }
    
    function float(uint256 number, uint8 decimal) internal view returns(uint256) {
        return number * (10 ** (_token.decimals() - decimal));
    }
    
    function float(uint256 number) internal view returns(uint256) {
        return number * (10 ** _token.decimals());
    }
}