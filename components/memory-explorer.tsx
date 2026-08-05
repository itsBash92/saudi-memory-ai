"use client";

import { useMemo, useState } from "react";
import { memories, places } from "@/lib/mock-data";

const cities = ["All", ...Array.from(new Set(places.map((place) => place.city)))];

export function MemoryExplorer() {
  const [city, setCity] = useState("All");

  const visiblePlaces = useMemo(
    () => places.filter((place) => city === "All" || place.city === city),
    [city],
  );

  return (
    <div>
      <div className="filter-row" aria-label="Filter places by city">
        {cities.map((item) => (
          <button
            type="button"
            key={item}
            className={city === item ? "filter-button is-active" : "filter-button"}
            onClick={() => setCity(item)}
            aria-pressed={city === item}
          >
            {item}
          </button>
        ))}
      </div>

      <div className="place-grid">
        {visiblePlaces.map((place) => {
          const memory = memories.find((item) => item.placeId === place.id);
          return (
            <article className={`place-card place-card-${place.accent}`} key={place.id}>
              <div className="place-visual" aria-hidden="true">
                <span className="place-year">{place.era}</span>
                <div className="place-landscape">
                  <i /><i /><i /><i />
                </div>
              </div>
              <div className="place-body">
                <div className="place-location">
                  <span>{place.city}</span>
                  <span>{Math.round(place.confidence * 100)}% confidence</span>
                </div>
                <h3>{place.name}</h3>
                <p>{place.summary}</p>
                <div className="tag-row">
                  {place.tags.map((tag) => <span key={tag}>{tag}</span>)}
                </div>
                {memory && (
                  <blockquote>
                    “{memory.excerpt}”
                    <footer>{memory.contributor} · circa {memory.approximateYear}</footer>
                  </blockquote>
                )}
                <div className="card-footer">
                  <span>{place.memoriesCount} preserved memories</span>
                  <button type="button" aria-label={`Open ${place.name}`}>Open memory →</button>
                </div>
              </div>
            </article>
          );
        })}
      </div>
    </div>
  );
}
