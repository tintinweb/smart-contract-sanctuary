pragma solidity 0.5.0; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   &#39; /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗     ██╗      ██████╗ ████████╗████████╗ ██████╗ 
██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗    ██║     ██╔═══██╗╚══██╔══╝╚══██╔══╝██╔═══██╗
███████║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝    ██║     ██║   ██║   ██║      ██║   ██║   ██║
██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗    ██║     ██║   ██║   ██║      ██║   ██║   ██║
██║  ██║   ██║   ██║     ███████╗██║  ██║    ███████╗╚██████╔╝   ██║      ██║   ╚██████╔╝
╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝    ╚═╝      ╚═╝    ╚═════╝ 
                                                                                         


// ----------------------------------------------------------------------------
// &#39;HyperLotto&#39; contract with following functionalities:
//      => Higher control by owner
//      => SafeMath implementation 
//
// Contract Name    : HyperLotto
// Decimals         : 18
//
// Copyright (c) 2018 HyperETH Inc. ( https://hypereth.net ) 
// Contract designed by: EtherAuthority ( https://EtherAuthority.io ) 
// ----------------------------------------------------------------------------
*/ 



//*****************************************************************//
//---------------------- SafeMath Library -------------------------//
//*****************************************************************//
    
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function subsafe(uint256 a, uint256 b) internal pure returns (uint256) {
    if(b <= a){
        return a - b;
    }else{
        return 0;
    }
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
    contract owned {
        address public owner;
    	using SafeMath for uint256;
    	
         constructor () public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }
    


contract HyperLOTTO is owned {
    
    using SafeMath for uint256;
    
    address[] public players;

    function enter() public payable{
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }

    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function pickWinner() public onlyOwner {
        address winner = players[random() % players.length];

        // In-built transfer function to send all money
        // from lottery contract to the player
        //winner.transfer(address(this).balance);
        players = new address[](0);
    }


    function getPlayers() public view returns(address[] memory) {
        // Return list of players
        return players;
    }
    
  
}