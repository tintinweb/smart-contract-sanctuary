pragma solidity ^0.4.18;

//기존 REDBLAKCTREE는 동일 가격의 주문을 처리할 수 없음
//이를 위해 동일가격 처리 방식을 넣었으며, 매수 매도의 처리방식도 달리하여 동일 가격의 주문 처리를 가능하게 하였음
//기존 RecBlackTree 라이브러리에서 독자적인 방식으로 직접 수정한 함수내역
//function find(Tree storage tree, uint value, bool isSell) public constant returns (uint32 parentId
//function placeAfter(Tree storage tree, uint32 parent, uint32 id, uint value, bool isSell) internal

library RedBlackTree {

    struct Item {
        bool red;
        uint32 parent;
        uint32 left;
        uint32 right;
        uint value;
    }

    struct Tree {
        uint32 root;
        mapping(uint32 => Item) items;
    }
/*
    function getItem(Tree storage tree, uint32 id) public constant returns (uint32 parent, uint32 left, uint32 right, uint value, bool red) 
    {
        require(id != 0);
        Item storage item = tree.items[id];
        parent = item.parent;
        left = item.left;
        right = item.right;
        value = item.value;
        red = item.red;
    }
*/
    function find(Tree storage tree, uint value, bool isSell) public constant returns (uint32 parentId) {

        uint32 id = tree.root;
        parentId = id;

        if (id == 0)
            return;

        Item storage item = tree.items[id];

        if (isSell == true)
        {
            while (id != 0)
            {
                if (value == item.value)
                {
                    id = item.right;
                    while (id != 0 && value == item.value)
                    {
                        parentId = id;
                        id = item.right;
                    }
                    return;
                }
    
                parentId = id;
    
                if (value > item.value)
                {
                    id = item.right;
    
                    if (id != 0)
                        parentId = id;
    
                    while (id != 0 && value == item.value)
                    {
                        parentId = id;
                        id = item.right;
                    }
    
                }
                else
                {
                    id = item.left;
    
                    if (id != 0)
                        parentId = id;
    
                    while (id != 0 && value == item.value)
                    {
                        parentId = id;
                        id = item.right;
                    }
                }
            }
        }
        else
        {
            while (id != 0)
            {
            if (value == item.value)
            {
                id = item.left;
                while (id != 0 && value == item.value)
                {
                    parentId = id;
                    id = item.left;
                }
                return;
            }

            parentId = id;

            if (value > item.value)
            {
                id = item.right;

                if (id != 0)
                    parentId = id;

                while (id != 0 && value == item.value)
                {
                    parentId = id;
                    id = item.left;
                }

            }
            else
            {
                id = item.left;

                if (id != 0)
                    parentId = id;

                while (id != 0 && value == item.value)
                {
                    parentId = id;
                    id = item.left;
                }
            }
        }
        }
        return parentId;
    }
/*
    function insert(Tree storage tree, uint32 id, uint value, bool isSell) internal
    {
        uint32 parent = find(tree, value, isSell);
        placeAfter(tree, parent, id, value, isSell);
    }
*/
    function placeAfter(Tree storage tree, uint32 parent, uint32 id, uint value, bool isSell) internal
    {
        Item memory item;
        item.value = value;
        item.parent = parent;
        item.red = true;

        if (parent != 0) {
            Item storage itemParent = tree.items[parent];

            if (value == itemParent.value)
            {
                if (isSell == true)
                {
                    item.right = itemParent.right;
    
                    if (item.right != 0)
                        tree.items[item.right].parent = id;
    
                    if (parent != 0)
                        itemParent.right = id;
                }
                else
                {
                    item.left = itemParent.left;
    
                    if (item.left != 0)
                        tree.items[item.left].parent = id;
    
                    if (parent != 0)
                        itemParent.left = id;
                }
            }
            else if (value < itemParent.value)
            {
                itemParent.left = id;
            }
            else
            {
                itemParent.right = id;
            }
        }
        else
        {
            tree.root = id;
        }

        tree.items[id] = item;
        insert1(tree, id);
    }

    function insert1(Tree storage tree, uint32 n) private
    {
        uint32 p = tree.items[n].parent;
        if (p == 0)
        {
            tree.items[n].red = false;
        }
        else
        {
            if (tree.items[p].red)
            {
                uint32 g = grandparent(tree, n);
                uint32 u = uncle(tree, n);

                if (u != 0 && tree.items[u].red)
                {
                    tree.items[p].red = false;
                    tree.items[u].red = false;
                    tree.items[g].red = true;
                    insert1(tree, g);
                }
                else
                {
                    if ((n == tree.items[p].right) && (p == tree.items[g].left))
                    {
                        rotateLeft(tree, p);
                        n = tree.items[n].left;
                    }
                    else if ((n == tree.items[p].left) && (p == tree.items[g].right))
                    {
                        rotateRight(tree, p);
                        n = tree.items[n].right;
                    }

                    insert2(tree, n);
                }
            }
        }
    }

    function insert2(Tree storage tree, uint32 n) internal
    {
        uint32 p = tree.items[n].parent;
        uint32 g = grandparent(tree, n);

        tree.items[p].red = false;
        tree.items[g].red = true;

        if ((n == tree.items[p].left) && (p == tree.items[g].left))
        {
            rotateRight(tree, g);
        }
        else
        {
            rotateLeft(tree, g);
        }
    }

    function remove(Tree storage tree, uint32 n) internal {
        uint32 successor;
        uint32 nRight = tree.items[n].right;
        uint32 nLeft = tree.items[n].left;

        if (nRight != 0 && nLeft != 0)
        {
            successor = nRight;
            while (tree.items[successor].left != 0)
            {
                successor = tree.items[successor].left;
            }

            uint32 sParent = tree.items[successor].parent;

            if (sParent != n)
            {
                tree.items[sParent].left = tree.items[successor].right;
                tree.items[successor].right = nRight;
                tree.items[sParent].parent = successor;
            }

            tree.items[successor].left = nLeft;

            if (nLeft != 0)
            {
                tree.items[nLeft].parent = successor;
            }
        }
        else if (nRight != 0)
        {
            successor = nRight;
        }
        else
        {
            successor = nLeft;
        }
        
        uint32 p = tree.items[n].parent;

        if (successor != 0)
            tree.items[successor].parent = p;

        if (p != 0)
        {
            if (n == tree.items[p].left)
            {
                tree.items[p].left = successor;
            }
            else
            {
                tree.items[p].right = successor;
            }
        }
        else
        {
            tree.root = successor;
        }

        if (!tree.items[n].red && successor != 0)
        {
            if (tree.items[successor].red)
            {
                tree.items[successor].red = false;
            }
            else
            {
                delete1(tree, successor);
            }
        }

        delete tree.items[n];
        delete tree.items[0];
    }

    function delete1(Tree storage tree, uint32 n) private
    {
        uint32 p = tree.items[n].parent;

        if (p != 0) {
            uint32 s = sibling(tree, n);
            if (tree.items[s].red)
            {
                tree.items[p].red = true;
                tree.items[s].red = false;
                if (n == tree.items[p].left)
                {
                    rotateLeft(tree, p);
                }
                else
                {
                    rotateRight(tree, p);
                }
            }
            delete2(tree, n);
        }
    }

    function delete2(Tree storage tree, uint32 n) private
    {
        uint32 s = sibling(tree, n);
        uint32 p = tree.items[n].parent;
        uint32 sLeft = tree.items[s].left;
        uint32 sRight = tree.items[s].right;
        if (!tree.items[p].red && !tree.items[s].red && !tree.items[sLeft].red && !tree.items[sRight].red)
        {
            tree.items[s].red = true;
            delete1(tree, p);
        }
        else
        {
            if (tree.items[p].red && !tree.items[s].red && !tree.items[sLeft].red && !tree.items[sRight].red)
            {
                tree.items[s].red = true;
                tree.items[p].red = false;
            }
            else
            {
                if (!tree.items[s].red)
                {
                    if (n == tree.items[p].left && !tree.items[sRight].red && tree.items[sLeft].red)
                    {
                        tree.items[s].red = true;
                        tree.items[sLeft].red = false;
                        rotateRight(tree, s);
                    }
                    else if (n == tree.items[p].right && !tree.items[sLeft].red && tree.items[sRight].red)
                    {
                        tree.items[s].red = true;
                        tree.items[sRight].red = false;
                        rotateLeft(tree, s);
                    }
                }
                
                tree.items[s].red = tree.items[p].red;
                tree.items[p].red = false;

                if (n == tree.items[p].left)
                {
                    tree.items[sRight].red = false;
                    rotateLeft(tree, p);
                }
                else
                {
                    tree.items[sLeft].red = false;
                    rotateRight(tree, p);
                }
            }
        }
    }

    function grandparent(Tree storage tree, uint32 n) private returns (uint32)
    {
        return tree.items[tree.items[n].parent].parent;
    }

    function uncle(Tree storage tree, uint32 n) private returns (uint32)
    {
        uint32 g = grandparent(tree, n);
        if (g == 0)
            return 0;

        if (tree.items[n].parent == tree.items[g].left)
            return tree.items[g].right;

        return tree.items[g].left;
    }

    function sibling(Tree storage tree, uint32 n) private returns (uint32)
    {
        uint32 p = tree.items[n].parent;

        if (n == tree.items[p].left)
        {
            return tree.items[p].right;
        }
        else
        {
            return tree.items[p].left;
        }
    }

    function rotateRight(Tree storage tree, uint32 n) private
    {
        uint32 pivot = tree.items[n].left;
        uint32 p = tree.items[n].parent;
        tree.items[pivot].parent = p;

        if (p != 0)
        {
            if (tree.items[p].left == n)
            {
                tree.items[p].left = pivot;
            }
            else
            {
                tree.items[p].right = pivot;
            }
        }
        else
        {
            tree.root = pivot;
        }

        tree.items[n].left = tree.items[pivot].right;

        if (tree.items[pivot].right != 0)
        {
            tree.items[tree.items[pivot].right].parent = n;
        }

        tree.items[n].parent = pivot;
        tree.items[pivot].right = n;
    }

    function rotateLeft(Tree storage tree, uint32 n) private
    {
        uint32 pivot = tree.items[n].right;
        uint32 p = tree.items[n].parent;
        tree.items[pivot].parent = p;

        if (p != 0) {
            if (tree.items[p].left == n)
            {
                tree.items[p].left = pivot;
            }
            else
            {
                tree.items[p].right = pivot;
            }
        }
        else
        {
            tree.root = pivot;
        }

        tree.items[n].right = tree.items[pivot].left;

        if (tree.items[pivot].left != 0)
        {
            tree.items[tree.items[pivot].left].parent = n;
        }

        tree.items[n].parent = pivot;
        tree.items[pivot].left = n;
    }
}