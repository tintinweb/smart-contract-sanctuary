/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface o {
    function getUnderlyingPrice(address) external view returns (uint);
}

contract ffregistry {
    address[] _forexs;
    mapping(address => address) public cy;
    address public governance;
    address public pendingGovernance;
    uint public applyGovernance;
    uint constant DELAY = 1 days;
    address public oracle;
    
    constructor() {
        governance = msg.sender;
        oracle = 0xde19f5a7cF029275Be9cEC538E81Aa298E297266;
        
        _init(0xFAFdF0C4c1CB09d430Bf88c75D88BB46DAe09967, 0x86BBD9ac8B9B44C95FFc6BAAe58E25033B7548AA);
        _init(0x1CC481cE2BD2EC7Bf67d1Be64d4878b16078F309, 0x1b3E95E8ECF7A7caB6c4De1b344F94865aBD12d5);
        _init(0x69681f8fde45345C3870BCD5eaf4A05a60E7D227, 0xecaB2C76f1A8359A06fAB5fA0CEea51280A97eCF);
        _init(0x5555f75e3d5278082200Fb451D1b6bA946D8e13b, 0x215F34af6557A6598DbdA9aa11cc556F5AE264B1);
        _init(0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27, 0x00e5c0774A5F065c285068170b20393925C84BF3);
        _init(0x95dFDC8161832e4fF7816aC4B6367CE201538253, 0x3c9f5385c288cE438Ed55620938A4B967c080101);
    }
    
    function _init(address _forex, address _cy) internal {
        _forexs.push(_forex);
        cy[_forex] = _cy;
    }
    
    modifier gov() {
        require(msg.sender == governance);
        _;
    }
    
    function _findIndex(address[] memory array, address element) internal pure returns (uint i) {
        for (i = 0; i < array.length; i++) {
            if (array[i] == element) {
                break;
            }
        }
    }

    function _remove(address[] storage array, address element) internal {
        uint _index = _findIndex(array, element);
        uint _length = array.length;
        if (_index >= _length) return;
        if (_index < _length-1) {
            array[_index] = array[_length-1];
        }

        array.pop();
    }
    
    function setOracle(address _oracle) external gov {
        oracle = _oracle;
    }
    
    function transferGovernance(address _governance) external gov {
        pendingGovernance = _governance;
        applyGovernance = block.timestamp + DELAY;
    }
    
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        require(block.timestamp > applyGovernance);
        governance = pendingGovernance;
    }
    
    function addForex(address _forex, address _cy) external gov {
        if (_findIndex(_forexs, _forex) == _forexs.length) {
            _forexs.push(_forex);
        }
        cy[_forex] = _cy;
    }
    
    function removeForex(address _forex) external gov {
        if (_findIndex(_forexs, _forex) < _forexs.length) {
            _remove(_forexs, _forex);
        }
    }
    
    function forex() external view returns (address[] memory) {
        return _forexs;
    }
    
    function price(address _forex) external view returns (uint) {
        return o(oracle).getUnderlyingPrice(cy[_forex]);
    }
}