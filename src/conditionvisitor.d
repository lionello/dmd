/**
 * Compiler implementation of the
 * $(LINK2 http://www.dlang.org, D programming language).
 *
 * Copyright:   Copyright (c) 1999-2016 by Digital Mars, All Rights Reserved
 * Authors:     $(LINK2 http://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(DMDSRC _constfold.d)
 */

module ddmd.conditionvisitor;

import ddmd.expression;
import ddmd.declaration;
import ddmd.visitor;
import ddmd.intrange;
import ddmd.dcast;
import ddmd.tokens;

extern (C++) final class ConditionVisitor : Visitor
{
    alias visit = super.visit;
public:
    bool invert = false;
    bool deadcode = false;

    override void visit(Expression e) { }

    override void visit(CastExp e)
    {
        push(e, TOKnotequal, null);
    }

    override void visit(EqualExp e)
    {
        push(e.e1, e.op, e.e2);
    }

    override void visit(CmpExp e)
    {
        push(e.e1, e.op, e.e2);
    }

    override void visit(VarExp e)
    {
        push(e, TOKnotequal, null);
    }

    override void visit(NotExp e)
    {
        invert = !invert;
        e.e1.accept(this);
        invert = !invert;
    }

    override void visit(OrOrExp e)
    {
        if (invert)
        {
            e.e1.accept(this);
            e.e2.accept(this);
        }
    }

    override void visit(AndAndExp e)
    {
        if (!invert)
        {
            e.e1.accept(this);
            e.e2.accept(this);
        }
    }

    void popRanges()
    {
        foreach (r; toPop)
        {
            r.rangeStack = r.rangeStack.next;
        }
    }

private:
    VarDeclaration[] toPop;

    VarDeclaration getVarDecl(Expression e)
    {
        if (e.op == TOKcast)
            e = (cast(CastExp)e).e1;
        VarDeclaration vd = e.op == TOKvar && e.type.isscalar() ? (cast(VarExp)e).var.isVarDeclaration() : null;
        return vd && !vd.type.isMutable() ? vd : null;
    }

    void push(Expression e1, TOK op, Expression e2)
    {
        VarDeclaration vd1 = getVarDecl(e1);
        VarDeclaration vd2 = e2 ? getVarDecl(e2) : null;
        if (vd1 || vd2)
        {
            IntRange r1 = getIntRange(e1);
            IntRange r2 = e2 ? getIntRange(e2) : IntRange(SignExtendedNumber(0), SignExtendedNumber(0));
            fixupRanges(r1, invert ? invertOp(op) : op, r2);
            pushRange(vd1, r1);
            pushRange(vd2, r2);
        }
    }

    void pushRange(VarDeclaration vd, IntRange ir)
    {
        if (ir.imin > ir.imax)
        {
            deadcode = true;
        }
        else if (vd)
        {
            vd.rangeStack = new IntRangeList(ir.imin, ir.imax, vd.rangeStack);
            toPop ~= vd;
        }
    }
}


static TOK invertOp(TOK op)
{
    switch (op)
    {
    case TOKlt:
        return TOKge;
    case TOKle:
        return TOKgt;
    case TOKgt:
        return TOKle;
    case TOKge:
        return TOKlt;
    case TOKequal:
        return TOKnotequal;
    case TOKnotequal:
        return TOKequal;
    default:
        assert(0);
    }
}

static void fixupRanges(ref IntRange v1, TOK op, ref IntRange v2)
{
    switch (op)
    {
    case TOKle:
        v1 = IntRange(v1.imin, v2.imax <= v1.imax ? v2.imax : v1.imax);
        v2 = IntRange(v1.imin >= v2.imin ? v1.imin : v2.imin, v2.imax);
        break;
    case TOKlt:
        v1 = IntRange(v1.imin, v2.imax <= v1.imax ? v2.imax - SignExtendedNumber(1) : v1.imax);
        v2 = IntRange(v1.imin >= v2.imin ? v1.imin + SignExtendedNumber(1) : v2.imin, v2.imax);
        break;
    case TOKge:
        v1 = IntRange(v2.imin >= v1.imin ? v2.imin : v1.imin, v1.imax);
        v2 = IntRange(v2.imin, v1.imax <= v2.imax ? v1.imax : v2.imax);
        break;
    case TOKgt:
        v1 = IntRange(v2.imin >= v1.imin ? v2.imin + SignExtendedNumber(1) : v1.imin, v1.imax);
        v2 = IntRange(v2.imin, v1.imax <= v2.imax ? v1.imax - SignExtendedNumber(1): v2.imax);
        break;
    case TOKequal:
        v2 = v1 = v1.intersectWith(v2);
        break;
    case TOKnotequal:
        if (v1.imin == v1.imax)
            v2 = IntRange(v2.imin + SignExtendedNumber((v1.imin == v2.imin)?1:0), v2.imax - SignExtendedNumber((v1.imax == v2.imax)?1:0));
        else if (v2.imin == v2.imax)
            v1 = IntRange(v1.imin + SignExtendedNumber((v1.imin == v2.imin)?1:0), v1.imax - SignExtendedNumber((v1.imax == v2.imax)?1:0));
        break;
    default:
        assert(0);
    }
}
