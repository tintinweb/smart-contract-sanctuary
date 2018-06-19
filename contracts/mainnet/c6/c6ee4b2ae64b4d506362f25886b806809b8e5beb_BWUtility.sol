pragma solidity ^0.4.21;

library BWUtility {
    
    // -------- UTILITY FUNCTIONS ----------


    // Return next higher even _multiple for _amount parameter (e.g used to round up to even finneys).
    function ceil(uint _amount, uint _multiple) pure public returns (uint) {
        return ((_amount + _multiple - 1) / _multiple) * _multiple;
    }

    // Checks if two coordinates are adjacent:
    // xxx
    // xox
    // xxx
    // All x (_x2, _xy2) are adjacent to o (_x1, _y1) in this ascii image. 
    // Adjacency does not wrapp around map edges so if y2 = 255 and y1 = 0 then they are not ajacent
    function isAdjacent(uint8 _x1, uint8 _y1, uint8 _x2, uint8 _y2) pure public returns (bool) {
        return ((_x1 == _x2 &&      (_y2 - _y1 == 1 || _y1 - _y2 == 1))) ||      // Same column
               ((_y1 == _y2 &&      (_x2 - _x1 == 1 || _x1 - _x2 == 1))) ||      // Same row
               ((_x2 - _x1 == 1 &&  (_y2 - _y1 == 1 || _y1 - _y2 == 1))) ||      // Right upper or lower diagonal
               ((_x1 - _x2 == 1 &&  (_y2 - _y1 == 1 || _y1 - _y2 == 1)));        // Left upper or lower diagonal
    }

    // Converts (x, y) to tileId xy
    function toTileId(uint8 _x, uint8 _y) pure public returns (uint16) {
        return uint16(_x) << 8 | uint16(_y);
    }

    // Converts _tileId to (x, y)
    function fromTileId(uint16 _tileId) pure public returns (uint8, uint8) {
        uint8 y = uint8(_tileId);
        uint8 x = uint8(_tileId >> 8);
        return (x, y);
    }
    
    function getBoostFromTile(address _claimer, address _attacker, address _defender, uint _blockValue) pure public returns (uint, uint) {
        if (_claimer == _attacker) {
            return (_blockValue, 0);
        } else if (_claimer == _defender) {
            return (0, _blockValue);
        }
    }
}