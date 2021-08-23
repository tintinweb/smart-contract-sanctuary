//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import 'Ownable.sol';
import 'SafeMath.sol';
import 'IBEP20.sol';

contract Auction is Ownable {
    using SafeMath for uint256;
    
    struct Lot {
        uint256 price;
        uint256 earn;
        address buyer;
    }
    
    enum TYPES{ HIGH, MIDDLE, LOW }
    
    IBEP20 private _token;
    
    Lot[] private highAuction;
    Lot[] private middleAuction;
    Lot[] private lowAuction;
    address[] private members;
    
    constructor(IBEP20 token) {
        _token = token;
    }
    
    function createAuction(uint8 highCount, uint8 middleCount, uint8 lowCount) public onlyOwner {
        for(uint8 h=0; h<highCount; h++) {
            highAuction.push(Lot(float(100), float(5) - float(2, 1) * h, address(0)));
        }

        for(uint8 m=0; m<middleCount; m++) {
            middleAuction.push(Lot(float(10), float(2) - float(1, 1) * m, address(0)));
        }

        for(uint8 l=0; l<lowCount; l++) {
            lowAuction.push(Lot(float(1), float(4, 1) - float(1, 2) * l, address(0)));
        }
    }
    
    function getAuctions(TYPES _type) public view returns(Lot[] memory _auction) {
        if(_type == TYPES.HIGH) {
            return highAuction;
        } else if(_type == TYPES.MIDDLE) {
            return middleAuction;
        } else if(_type == TYPES.LOW) {
            return lowAuction;
        }
    }
    
    function makeBid(TYPES _type, uint8 id) public payable {
        for(uint16 i=0; i<members.length; ++i) {
            require(members[i] != _msgSender(), 'You are already participating in this auction');
        }
        
        if(_type == TYPES.HIGH) {
            
            require(highAuction[id].buyer == address(0), "Lot was bought");
            _token.transferFrom(_msgSender(), address(this), highAuction[id].price);
            highAuction[id].buyer = _msgSender();
            members.push(_msgSender());
            
        } else if(_type == TYPES.MIDDLE) {

            require(middleAuction[id].buyer == address(0), "Lot was bought");
            _token.transferFrom(_msgSender(), address(this), middleAuction[id].price);
            middleAuction[id].buyer = _msgSender();
            members.push(_msgSender());
            
        } else if(_type == TYPES.LOW) {
            
            require(lowAuction[id].buyer == address(0), "Lot was bought");
            _token.transferFrom(_msgSender(), address(this), lowAuction[id].price);
            lowAuction[id].buyer = _msgSender();
            members.push(_msgSender());
            
        } else {
            require(false, "Wrong type");
        }
    }
    
    function closeAction() public onlyOwner {
        for(uint8 h=0; h<highAuction.length; h++) {
            if(highAuction[h].buyer != address(0)) {
                _token.transfer(highAuction[h].buyer, highAuction[h].price + highAuction[h].earn);
            }
        }
        delete highAuction;
        
        for(uint8 h=0; h<middleAuction.length; h++) {
            if(middleAuction[h].buyer != address(0)) {
                _token.transfer(middleAuction[h].buyer, middleAuction[h].price + middleAuction[h].earn);
            }
        }
        delete middleAuction;
        
        for(uint8 h=0; h<lowAuction.length; h++) {
            if(lowAuction[h].buyer != address(0)) {
                _token.transfer(lowAuction[h].buyer, lowAuction[h].price + lowAuction[h].earn);
            }
        }
        delete lowAuction;
    }
    
    function random(uint8 min, uint8 max) internal view returns (uint8) {
        require(max > min, "Max must be more than min");
        return min + uint8(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, min, max))) % (max - min + 1));
    }
    
    function float(uint256 number, uint8 decimal) internal view returns(uint256) {
        return number * (10 ** (_token.decimals() - decimal));
    }
    
    function float(uint256 number) internal view returns(uint256) {
        return number * (10 ** _token.decimals());
    }
}