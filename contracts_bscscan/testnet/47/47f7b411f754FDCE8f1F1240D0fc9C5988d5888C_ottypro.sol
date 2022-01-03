// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ottypro is ERC20{

    uint256 prizePool;
    uint hodlersLength;
    mapping(uint => address) hodlers;
    mapping(address => bool) isAlreadyHodler;
    mapping(address => bool) participate;

    constructor() ERC20 ("OtteryCoin", "OTTO"){
        hodlers[0] = msg.sender;
        participate[msg.sender] = true;
        isAlreadyHodler[msg.sender] = true;
        hodlersLength = 1;
        _mint(hodlers[0], 700000000000000000000000000000);
        prizePool = 300000000000000000000000000000;
    }
    
    function getWinner(uint seed) private view returns (address){
        address winner;
        bool foundOne = false;
        while(foundOne == false){
            uint randomIndex = random(hodlersLength, seed);
            if(participate[hodlers[randomIndex]] == true){
                winner = hodlers[randomIndex];
                foundOne = true; 
            }
        }
        
        return winner;
    }

    function getHodlersCount() public view returns(uint){
        return hodlersLength;
    }

    function getHodlers() public view returns (address[] memory){
        address[] memory allAddresses = new address[](hodlersLength);
        for(uint i=0; i<hodlersLength; i++){
            allAddresses[i] = hodlers[i];
        }

        return allAddresses;
    }

    function getPrizePool() public view returns (uint256){
        return prizePool / 200;
    }

    function getFirstPrize() public view returns (uint256){
        return getPrizePool() / 2;
    }

    function getSecondPrize() public view returns (uint256){
        return getPrizePool() / 10;
    }
    
    function getThirdPrize() public view returns (uint256){
        return getPrizePool() / 50;
    }

    function getOwner() public view returns (address){
        return hodlers[0];
    }

    function getParticipateCount() public view returns (uint){
        uint countParticipates = 0;
        for(uint i=0; i<hodlersLength; i++){
            if(participate[hodlers[i]] == true){
                countParticipates++;
            }
        }

        return countParticipates;

    }

    function giveaway(uint seed) public returns (address [] memory){

        require(_msgSender() == hodlers[0], "Permission denied!");
        address[] memory winner = new address[](10);

        for(uint i=0; i<10;i++){
            seed++;
            winner[i] = getWinner(seed);
        }

        uint256 prize = prizePool / 200;
        
        uint256 firstPrize = prize/2;
        uint256 secondPrize = prize/10;
        uint256 thirdPrize = prize/50;
        
        _mint(winner[0], firstPrize);
        _mint(winner[1], secondPrize);
        _mint(winner[2], secondPrize);
        _mint(winner[3], secondPrize);
        _mint(winner[4], secondPrize);
        for(uint i=0; i<5; i++){
            _mint(winner[i+5], thirdPrize);
        }
        prizePool -= prize;

        return winner;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(msg.sender != address(0) && recipient != address(0)){
            if (isAlreadyHodler[recipient] != true){
                participate[recipient] = false;
                hodlers[hodlersLength] = recipient;
                hodlersLength++;
                isAlreadyHodler[recipient] = true;
            }
            
            if(balanceOf(_msgSender()) - amount < 1000000000000000000000000){
                participate[_msgSender()] = false;
            }
            
            if (balanceOf(recipient) + amount >= 1000000000000000000000000){
                participate[recipient] = true;
            }
        }
        

        _transfer(_msgSender(), recipient, amount);
        
        return true;
    }
    
    function participates(address addr) public view returns (bool){
        return participate[addr];
    }

    function random(uint range, uint seed) public view returns (uint) {
        // sha3 and now have been deprecated
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp + seed)))%range;

        // convert hash to integer
        // players is an array of entrants
    }
}