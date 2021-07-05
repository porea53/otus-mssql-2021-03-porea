using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

[Serializable]
[Microsoft.SqlServer.Server.SqlUserDefinedAggregate(Format.Native)]
public struct AvgPrice
{
    SqlDouble avgPrice;
    SqlDouble amount;
    SqlDouble qty;

    public void Init()
    {
        avgPrice = amount = qty = 0;
    }

    public void Accumulate(SqlDouble lineAmount, SqlDouble lineQty)
    {
        amount += lineAmount;
        qty += lineQty;
    }

    public void Merge (AvgPrice Group)
    {
        amount += Group.amount;
        qty += Group.qty;
    }

    public SqlDouble Terminate ()
    {
        if(qty == 0)
        {
            return SqlDouble.Null;
        }

        return amount/qty;
    }
}
