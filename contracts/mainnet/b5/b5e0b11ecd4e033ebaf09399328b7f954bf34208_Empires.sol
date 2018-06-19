pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Empires is Ownable {

    uint curr_rate = 50000000000000000; // 0.05 Ether
    uint withraw_balance = 0;

    struct Flag {
        address[] spotOwner;
        bytes32[] spotTxt;
        uint spotRate;
        uint prize;
        uint16 spotWon;
    }

    Flag emptyFlag;

    mapping (uint16 => Flag[]) public cntry_flgs;

    function getRate () external view returns (uint) {
        return curr_rate;
    }

    function setRate (uint newRate) external onlyOwner {
        curr_rate = newRate;
    }

    function regSpot (uint16 cntryId, bytes32 stxt) private {

        cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotOwner.push(msg.sender);
        cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotTxt.push(stxt);
        cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].prize = cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].prize + (cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotRate * 70 / 100);
        withraw_balance = withraw_balance + cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotRate - (cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotRate * 70 / 100);

    }

    function createFlag (uint16 cntryId, uint sRate) private {

        cntry_flgs[cntryId].push(Flag(new address[](0), new bytes32[](0), sRate, 0, 1000));

    }

    function completedFlag (uint16 cntryId) private {

        //generate spotWon
        uint16 randomSpot = uint16(uint(keccak256(now, msg.sender)) % 600);

        // transfer to winner
        cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotOwner[randomSpot].transfer(cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].prize);

        cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotWon = randomSpot;

    }

    function regSpots (uint16 cntryId, uint16 numOfSpots, bytes32 stxt) external payable {

        require (numOfSpots > 0 && numOfSpots <= 600);

        uint i;
        uint j;
        uint j1;
        uint flagCompleted;

        // check active flag exists:
        if (cntry_flgs[cntryId].length > 0) {
          
            require(msg.value == cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotRate * numOfSpots);

            i = cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotOwner.length;

            if (600-i >= numOfSpots) {

                j = numOfSpots;

                while (j > 0) {

                    regSpot(cntryId, stxt);
                    j --;
                    i ++;

                }

            } else {
              // flag spots overflow

                j1 = 600-i;
                j = numOfSpots - j1;

                while (j1 > 0) {

                    regSpot(cntryId, stxt);
                    j1 --;
                    i ++;

                }

                uint currRateHolder = cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotRate;

                // flag completion
                completedFlag (cntryId);
                flagCompleted = 1;

                // create new flag
                createFlag(cntryId, currRateHolder);

                i = 0;

                while (j > 0) {

                    regSpot(cntryId, stxt);
                    j --;
                    i ++;
                }

        }

      } else {

            require(msg.value == curr_rate * numOfSpots);

            // create new flag
            createFlag(cntryId, curr_rate);

            i = 0;
            j = numOfSpots;

            while (j > 0) {

                regSpot(cntryId, stxt);
                j --;
                i ++;
            }

      }
      
      // check flag completion
        if (i==600) {
            completedFlag (cntryId);
            flagCompleted = 1;
            createFlag(cntryId, curr_rate);
        }

        UpdateFlagList(cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotOwner, cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotTxt, flagCompleted);

    }

    event UpdateFlagList(address[] spotOwners,bytes32[] spotTxt, uint flagCompleted);

    function getActiveFlag(uint16 cntryId) external view returns (address[],bytes32[],uint,uint,uint16) {
      // check active flag exists:
        if (cntry_flgs[cntryId].length > 0) {
            return (cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotOwner, 
            cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotTxt, 
            cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotRate, 
            cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].prize, 
            cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotWon);
        } else {
            return (emptyFlag.spotOwner, 
            emptyFlag.spotTxt, 
            emptyFlag.spotRate, 
            emptyFlag.prize, 
            emptyFlag.spotWon);      
        }
    }

    function getCompletedFlag(uint16 cntryId, uint16 flagId) external view returns (address[],bytes32[],uint,uint,uint16) {
        return (cntry_flgs[cntryId][flagId].spotOwner, 
        cntry_flgs[cntryId][flagId].spotTxt, 
        cntry_flgs[cntryId][flagId].spotRate, 
        cntry_flgs[cntryId][flagId].prize, 
        cntry_flgs[cntryId][flagId].spotWon);
    }


    function getActiveFlagRate(uint16 cntryId) external view returns (uint) {
        // check active flag exists:
        if (cntry_flgs[cntryId].length > 0) {
            return cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotRate;
        } else {
            return curr_rate;
        }
    }

    function getCountrySpots(uint16 cntryId) external view returns (uint) {
        if (cntry_flgs[cntryId].length > 0) {
            return (cntry_flgs[cntryId].length-1)*600 + cntry_flgs[cntryId][cntry_flgs[cntryId].length-1].spotOwner.length;
        } else {
            return 0;
        }
    }

    function withdraw() external onlyOwner {
        uint tb = withraw_balance;
        owner.transfer(tb);
        withraw_balance = withraw_balance - tb;
    }

    function getWithdrawBalance () external view onlyOwner returns (uint) {
        return withraw_balance;
    }

    function() public payable { }

}