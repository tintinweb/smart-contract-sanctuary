// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

//imports
import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol" ; 

//@title Official NRT Presale Contract
//@author No Rug Token Team
contract NRT_Presale is Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) public _balances;

    uint256 public _minimum = 0.5 ether ; //mimimum buy amount
    uint256 public _maximum = 50 ether ; //maximum buy amount, prevent whales
    uint256 public hardcap = 767 ether ; //balance cannot exceed harcap
    
    uint256 public duration = 3 * 86400 ; //three days
    uint256 public starting_time ; //unix timestamp of presale start
    
    bool public hasStarted = false ; //presale status

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
    
    /**
     * @dev Function that gets called on receival of ether. 
     *      Requirements:   the contract has to be online, 
     *                      should not have ended, 
     *                      the hardcap shouldn't be reached yet,
     *                      the value must be at least minimum max maximum
     */
    receive() external payable {
        require(hasStarted == true, "Presale not online") ; 
        require(block.timestamp <= starting_time + duration, "Presale has ended") ;
        require(address(this).balance <= hardcap, "Harcap reached") ; 
        require(msg.value >= _minimum && msg.value <= _maximum, "Value does not exceed minimum amount or exceeds maximum amount") ; 
        
        _balances[msg.sender] += msg.value ; 
    }
    
    /**
     * @dev Start presale by saving unix timestamp for sale duration
     */
    function start_presale() public onlyOwner {
        hasStarted = true ; 
        starting_time = block.timestamp ; 
    }
    
    /**
     * @dev Stop presale
     */
    function stop_presale() public onlyOwner {
        hasStarted = false ; 
    }
    
    /**
     * @dev Withdraw ether locked in presale contract, only available after presale
     */
    function withdraw() public onlyOwner {
        require(hasStarted == false, "Presale not online") ; 
        require(block.timestamp >= starting_time + duration, "Presale has not ended yet") ; 
        msg.sender.transfer(address(this).balance) ; 
    }
    
    /**
     * @dev Adjust hardcap limit
     * @param ether_amount hardcap in ethereum (e.g. 100 ETH hardcap -> ether_amount = 100)
     */
    function set_hardcap(uint256 ether_amount) public onlyOwner {
        hardcap = ether_amount * 1 ether ; 
    } 
    
    /**
     * @dev Set tokensale duration
     * @param new_duration Duration of the presale in seconds
     */
    function set_duration(uint256 new_duration) public onlyOwner {
        duration = new_duration ; 
    }
}
