pragma solidity ^0.4.24;


library Math {
  function abs(int256 a) pure internal returns (int256) {
      if (a < 0) {
          return -a;
      } else {
          return a;
      }
  }
}

contract LottoProducer {
    // We bring the force from 5 Galaxy and Dark Dimension to produce your amazing lotto number.
    function produceLottoNumber(uint256 _temp, uint256 _power) public view returns (uint256) {
        uint256 temp = nonZero(_temp);
        uint256 power = nonZero(_power);
        
        uint256 lottoNumber = random(temp * power);
        lottoNumber = lottoNumber % 100;
        return lottoNumber;
    }
    
    function random(uint256 nonce) public view returns (uint256) {
        return uint256(keccak256(block.timestamp, block.difficulty, nonce));
    }
    
    function nonZero(uint256 value) public pure returns (uint256) {
        return value == 0 ? 1 : value;
    }
    
    // Helper
    function cloneArray(uint256[] array, uint256 length) view returns (uint256[]) {
        uint256[] memory newArray = new uint256[](length);
        for (uint8 i = 0; i < length; i++) {
            newArray[i] = array[i];
        }
        return newArray;
    }
}

contract Lottoreum is LottoProducer {
    using Math for int256;

    uint256[]   public players;
    uint256     public finalNumber;
    
    // params: _temp: Unstable temperature from Dark Dimension
    // params: _power: A power from your relate-couple from other side of galaxy
    // return: player index
    function newPlayer(uint256 _temp, uint256 _power) public returns (uint256) {
        uint256 lottoNumber = produceLottoNumber(_temp, _power);
        
        players.push(lottoNumber);
        
        return players.length - 1;
    }
    
    /// params: _finalNumber: Final Number (2-digits) from Lotto Announce
    //  Return: Winner indexs
    function processWinner() public returns (uint256[]) {
        finalNumber = produceLottoNumber(random(1), random(2));
    }
    
    function winners() public returns (uint256[]) {
        int256 nearestDistance = -1;
        
        // Find distance to final number
        int256[] memory distances = new int256[](players.length);
        for (uint8 i = 0; i < players.length; i++) {
            distances[i] = int256(finalNumber - players[i]).abs();
            
            if (-1 == nearestDistance) {
                nearestDistance = distances[i];
            } else if (distances[i] < nearestDistance) {
                nearestDistance = distances[i];
            }
        }
        
        uint256[] memory tmpWinners = new uint256[](players.length);
        uint256 winnerIndex = 0;
        // Who has nearest distance is winnders
        for (uint8 d_i = 0; d_i < distances.length; d_i++) {
            if (distances[d_i] == nearestDistance) {
                tmpWinners[winnerIndex] = d_i;
                winnerIndex++;
            }
        }
        
        return cloneArray(tmpWinners, winnerIndex);
    }
    
    // Clear out universe
    function clearGame() public {
        delete players;
        finalNumber = 0;
    }

    function playerCount() public view returns (uint256) {
      return players.length;
    }
    
    function winnerCount() public view returns (uint256) {
      return winners().length;
    }
}