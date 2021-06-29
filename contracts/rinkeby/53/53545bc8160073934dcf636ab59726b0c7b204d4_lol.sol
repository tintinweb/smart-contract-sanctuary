/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

contract lol {

    struct Position {
        uint256 depositTime;
        uint256 period;
        uint256 amount;
        uint256 positionId;
        bool status;
    }
    
    mapping (address => Position[]) depositedTokens;
    function getPositions(address holder) public view returns (Position[] memory) {
        Position[] memory ValidPosition;
         for (uint256 i = 0; i < depositedTokens[holder].length; i++) {
            if (depositedTokens[holder][i].status==true){
                ValidPosition[i]=depositedTokens[holder][i];
            }
        }
        return ValidPosition;
    }
    function deposit(uint256 amountToDeposit, uint256 period) external {
        depositedTokens[msg.sender].push(Position(block.timestamp,period,amountToDeposit,depositedTokens[msg.sender].length,true));
    }

}