/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.4.23;

contract SmartScore {
    using StringUtils for string;
    
	struct Score {
	    // 学生ID
		uint uid; 
		// 课程ID
		uint cid; 
		// m为被其他学生发现并成功评价的实验操作错误数量
		uint m; 
		// n为成功评价其他学生实验操作错误数量
		uint n; 
		// 分数
		uint score; 
	}
	//学生ID_课程ID映射分数
	mapping(string=>uint) scoresMapping;
	//当前最高分Score映射
	mapping(uint=>Score) maxscoreMapping;

	// 设置完成后，计算学生成绩
    function calc(uint[4] memory data) public payable {
		uint uid = data[0];
		uint cid = data[1];
		uint m = data[2];
		uint n = data[3];
		require(
            m != n,
            "参数错误"
        );
		//当前学生信息
        Score memory score = Score(uid, cid, m, n, 0);
        // 找出最高分数，以n-m的值作为参考值
    	Score memory maxScore = maxscoreMapping[0];
        int a1 = int(maxScore.n - maxScore.m);
		int a2 = int(score.n - score.m);
		if(a2 > a1 || maxScore.n - maxScore.m == 0) {
			maxScore = score;
		}
 		//	计算alpha参数的公式为：100 = 80 + (n - m) * alpha
    	uint alpha = 20 / (maxScore.n - maxScore.m);
 
    	// 计算学生的成绩
        uint value = 80 + (score.n - score.m) * alpha;
        
        if(value > maxScore.score) {
            score.score = value;
			maxscoreMapping[0] = score;
		}
       
        // 存储学员的成绩
        scoresMapping[uint2str(score.uid).concat("_").concat(uint2str(score.cid))] = value;
    }
    
    // 得到学生ID_课程ID分数 
    function u_score(uint uid, uint cid) public view returns (uint256) {
    	return scoresMapping[uint2str(uid).concat("_").concat(uint2str(cid))];
    }
    
    
    // 得到最高分数 
    function max_score() public view returns (uint256) {
    	return maxscoreMapping[0].score;
    }
    
    function uint2str(uint i) internal pure returns (string memory c) {
    	if (i == 0) {
    	    return "0";
    	}
    	uint j = i;
    	uint length;
    	while (j != 0){
    		length++;
    		j /= 10;
    	}
    	bytes memory b = new bytes(length);
    	uint k = length - 1;
    	while (i != 0){
    		b[k--] = byte(uint8(48 + i % 10));
    		i /= 10;
    	}
    	return string(b);
    }
}

library StringUtils {
    function concat(string memory self, string memory s) internal pure returns (string memory) {
		bytes memory _a = bytes(self);
		bytes memory _b = bytes(s);
		bytes memory b = new bytes(_a.length + _b.length);
		uint k = 0;
		uint i = 0;
		for (i = 0; i < _a.length; i++) {
		    b[k++] = _a[i];
		}
		for (i = 0; i < _b.length; i++) {
		    b[k++] = _b[i];
		}
		return string(b);
	}

}