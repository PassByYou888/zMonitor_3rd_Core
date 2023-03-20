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
unit M3C_Agg.ConvClipPolygon;

{$DEFINE FPC_DELPHI_MODE}
{$I M3C_Define.inc}
interface
uses
  M3C_Agg.Basics,
  M3C_Agg.ConvAdaptorVpgen,
  M3C_Agg.VpGenClipPolygon,
  M3C_Agg.VertexSource;

type
  TAggConvClipPolygon = class(TAggConvAdaptorVpgen)
  private
    FGenerator: TAggVpgenClipPolygon;
    function GetX1: Double;
    function GetY1: Double;
    function GetX2: Double;
    function GetY2: Double;
  public
    constructor Create(Vs: TAggVertexSource);
    destructor Destroy; override;

    procedure SetClipBox(x1, y1, x2, y2: Double);

    property x1: Double read GetX1;
    property y1: Double read GetY1;
    property x2: Double read GetX2;
    property y2: Double read GetY2;
  end;

implementation


{ TAggConvClipPolygon }

constructor TAggConvClipPolygon.Create;
begin
  FGenerator := TAggVpgenClipPolygon.Create;

  inherited Create(Vs, FGenerator);
end;

destructor TAggConvClipPolygon.Destroy;
begin
  FGenerator.Free;
  inherited;
end;

procedure TAggConvClipPolygon.SetClipBox(x1, y1, x2, y2: Double);
begin
  TAggVpgenClipPolygon(Vpgen).SetClipBox(x1, y1, x2, y2);
end;

function TAggConvClipPolygon.GetX1: Double;
begin
  Result := TAggVpgenClipPolygon(Vpgen).x1;
end;

function TAggConvClipPolygon.GetY1: Double;
begin
  Result := TAggVpgenClipPolygon(Vpgen).y1;
end;

function TAggConvClipPolygon.GetX2: Double;
begin
  Result := TAggVpgenClipPolygon(Vpgen).x2;
end;

function TAggConvClipPolygon.GetY2: Double;
begin
  Result := TAggVpgenClipPolygon(Vpgen).y2;
end;

end.
