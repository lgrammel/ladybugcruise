# tooltip
tooltip = d3.select("body")
	.append("div")
	.style("position", "absolute")
	.style("z-index", "10")
	.style("visibility", "hidden")
  .classed('tooltip', true)
	.text("a simple tooltip")

# Code based on Polymaps example from Mike Bostock http://bl.ocks.org/899670
po = org.polymaps
map = po.map().container(d3.select("#map").append("svg:svg").node())
        .zoom(4)
        .center({lat: 5, lon: -130})
        .add(po.drag())
        .add(po.wheel().smooth(false))
        .add(po.dblclick())
        .add(po.arrow())

# background tiles from Stamen http://maps.stamen.com
map.add(po.image().url(po.url("http://tile.stamen.com/watercolor/{Z}/{X}/{Y}.jpg")))

# generic transform function
transform = (location) ->
  d = map.locationPoint(location)
  "translate(" + d.x + "," + d.y + ")"
cardinalLine = d3.svg.line().x((d) => d.x).y((d) => d.y ).interpolate("cardinal")
linearLine = d3.svg.line().x((d) => d.x).y((d) => d.y ).interpolate("linear")

# layer with additional marks
referenceLayer = d3.select("#map svg").insert("svg:g");

# 3 reference points (could be moved to separate CSV file)
referencePoints = [
  {lat: 22.889722, lon: -109.915556, label: "Cabo San Lucas", wikipedia: "http://en.wikipedia.org/wiki/Cabo_San_Lucas"},
  {lat: 18.366667, lon: -114.733333, label: "Clarion Island", wikipedia: "http://en.wikipedia.org/wiki/Clarion_Island"},
  {lat: -9.75, lon: -139, label: "Hiva Oa in the Marquesas", wikipedia: "http://en.wikipedia.org/wiki/Hiva_Oa"}
]
marker = referenceLayer.selectAll("g.destination").data(referencePoints).enter().append("g").attr("transform", transform)
marker.append("circle")
  .attr("class", "destination")
  .attr("r", 10)
  .attr("fill", "#5F9EA0")
  .attr("text", (d) => d.label)
  .on("mouseover.tooltip", -> tooltip.style("visibility", "visible"))
  .on("mousemove.tooltip", ->
    event = d3.event
    tooltip.style("top", (event.pageY + 15) + "px")
           .style("left",(event.pageX + 20) + "px")
           .html(d3.select(this).attr('text'))
   )
  .on("mouseout.tooltip", -> tooltip.style("visibility", "hidden"))
  .on("click", (d) => window.open(d.wikipedia ,"_blank"))
map.on("move", -> referenceLayer.selectAll("g").attr("transform", transform))

# Equator
equator = [ { lat: 0, lon: -270 }, { lat: 0, lon: 270}]
mappedEquator = (d) =>
  linearLine(equator.map((d) => map.locationPoint(d)))

referenceLayer.selectAll("g.equator").data(equator).enter()
.append("path")
.attr("fill", "none")
.attr("stroke", "#b00")
.attr("stroke-width", ".5")
.attr("stroke-dasharray", "12 12")
.attr("d", (d) => mappedEquator(d))

map.on("move", -> referenceLayer.selectAll("path").attr("d",  (d) => mappedEquator(d)))

# daily positions
resultHandler = (data) ->

  # create line
  mappedLine = (d) =>
    cardinalLine(data.map((d) => map.locationPoint(d)))
  lineLayer = d3.select("#map svg").append("g");
  lineLayer.selectAll("g").data([data]).enter()
    .append("path")
    .attr("fill", "none")
    .attr("stroke", "#666")
    .attr("stroke-width", "4")
    .attr("d", (d) => mappedLine(d))

  map.on("move", -> lineLayer.selectAll("path").attr("d",  (d) => mappedLine(d)))

  # Insert our layer beneath the compass.
  layer = d3.select("#map svg").append("g")

  marker = layer.selectAll("g").data(data).enter().append("g")
                .attr("transform", transform)

  map.on("move", -> layer.selectAll("g").attr("transform", transform))

  marker.append("circle")
        .attr("class", "location")
        .attr("r", 4.5)
        .attr("fill", "#FF7F50")
        .attr("text", (d) => d.day + ": <b>" + d.title + "</b><br/>" + d.date + " Zulu")
        .on("mouseover.tooltip", -> tooltip.style("visibility", "visible"))
        .on("mousemove.tooltip", ->
          event = d3.event
          tooltip.style("top", (event.pageY + 15) + "px")
                 .style("left",(event.pageX + 20) + "px")
                 .html(d3.select(this).attr('text'))
         )
        .on("mouseout.tooltip", -> tooltip.style("visibility", "hidden"))
        .on("click", (d) => window.open(d.blogpost ,"_blank"))

map.add(po.compass().pan("none"))

do -> d3.csv("ladybugcruise.csv", resultHandler)