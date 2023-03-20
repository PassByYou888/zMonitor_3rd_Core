{ ****************************************************************************** }
{ * memory Rasterization AGG support                                           * }
{ ****************************************************************************** }


(*
  ////////////////////////////////////////////////////////////////////////////////
  //                                                                            //
  //  Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod')             //
  //    Maintained by Christian-W. Budde (Christian@pcjv.de)                    //
  //    Copyright (c) 2012-2017                                                 //
  //                                                                            //
  //  Based on:                                                                 //
  //    Pascal port by Milan Marusinec alias Milano (milan@marusinec.sk)        //
  //    Copyright (c) 2005-2006, see http://www.aggpas.org                      //
  //                                                                            //
  //  Original License:                                                         //
  //    Anti-Grain Geometry - Version 2.4 (Public License)                      //
  //    Copyright (C) 2002-2005 Maxim Shemanarev (http://www.antigrain.com)     //
  //    Contact: McSeem@antigrain.com / McSeemAgg@yahoo.com                     //
  //                                                                            //
  //  Permission to copy, use, modify, sell and distribute this software        //
  //  is granted provided this copyright notice appears in all copies.          //
  //  This software is provided "as is" without express or implied              //
  //  warranty, and with no claim as to its suitability for any purpose.        //
  //                                                                            //
  ////////////////////////////////////////////////////////////////////////////////
*)
unit M3C_Agg.SpanGenerator;

{$DEFINE FPC_DELPHI_MODE}
{$I M3C_Define.inc}
interface
uses
  M3C_Agg.Basics,
  M3C_Agg.SpanAllocator,
  M3C_Agg.VertexSource,
  M3C_Agg.Color32;

type
  TAggSpanGenerator = class(TAggCustomVertexSource)
  private
    FAlloc: TAggSpanAllocator;
    procedure SetAllocator(Alloc: TAggSpanAllocator);
  public
    constructor Create(Alloc: TAggSpanAllocator);

    procedure Prepare(MaxSpanLength: Cardinal); virtual;
    function Generate(x, y: Integer; Len: Cardinal): PAggColor; virtual; abstract;

    property Allocator: TAggSpanAllocator read FAlloc write SetAllocator;
  end;

implementation


{ TAggSpanGenerator }

constructor TAggSpanGenerator.Create(Alloc: TAggSpanAllocator);
begin
  FAlloc := Alloc;
end;

procedure TAggSpanGenerator.SetAllocator(Alloc: TAggSpanAllocator);
begin
  FAlloc := Alloc;
end;

procedure TAggSpanGenerator.Prepare(MaxSpanLength: Cardinal);
begin
  FAlloc.Allocate(MaxSpanLength);
end;

end.
