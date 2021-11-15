// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library SummingPriorityQueue {

    struct Heap {
        uint256[] keys;
        mapping(uint256 => uint256) map;
        uint256 totalEnqueuedAmount;
    }

    modifier notEmpty(Heap storage self) {
        require(self.keys.length > 1);
        _;
    }

    function top(Heap storage self) public view notEmpty(self) returns(uint256) {
        return self.keys[1];
    }

    function dequeue(Heap storage self) public notEmpty(self) {
        require(self.keys.length > 1);
        
        uint256 topKey = top(self);
        self.totalEnqueuedAmount -= self.map[topKey];
        delete self.map[topKey];
        self.keys[1] = self.keys[self.keys.length - 1];
        self.keys.pop();

        uint256 i = 1;
        while (i * 2 < self.keys.length) {
            uint256 j = i * 2;

            if (j + 1 < self.keys.length)
                if (self.keys[j + 1] < self.keys[j])
                    j++;
            

            if (self.keys[i] < self.keys[j])
                break;

            (self.keys[i], self.keys[j]) = (self.keys[j], self.keys[i]);
            i = j;
        }
    }

    function enqueue(Heap storage self, uint256 key, uint256 value) public {
        if (self.keys.length == 0) 
            self.keys.push(0); // initialize
        
        self.keys.push(key);
        uint256 i = self.keys.length - 1;

        while (i > 1 && self.keys[i / 2] > self.keys[i]) {
            (self.keys[i / 2], self.keys[i]) = (key, self.keys[i / 2]);
            i /= 2;
        }

        self.map[key] = value;
        self.totalEnqueuedAmount += value;
    }

    function drain(Heap storage self, uint256 ts) public {
        while (self.keys.length > 1 && top(self) < ts)
            dequeue(self);
    }
}

